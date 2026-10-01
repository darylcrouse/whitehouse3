# frozen_string_literal: false
#
# Legacy RJS support.
#
# The application predates Unobtrusive JS: ~61 controller actions use
# `render :update do |page| ... end` (Rails 2 RJS), including nested
# `render(:partial => ...)` calls whose HTML is embedded into the generated
# JavaScript. Modern Rails removed RJS entirely, so this layer:
#
#   1. intercepts `render :update { |page| ... }`,
#   2. gives the block a PageRenderer that emits Prototype-era JavaScript
#      (the app still ships prototype.js + scriptaculous + jrails in
#      public/javascripts, so the emitted calls are live client-side),
#   3. returns `render_to_string` for nested partial renders inside the block,
#   4. responds with content-type text/javascript.
#
# Generated JS is dispatched by the app's own Ajax helpers (Prototype) or by
# Rails' classic `link_to_remote`-style helpers shimmed in ApplicationHelper.

module LegacyRjs
  class Collector
    def initialize
      @lines = []
    end

    def <<(line)
      @lines << line.to_s
    end

    def to_s
      @lines.join("\n")
    end
  end

  # Proxy for `page['element_id']` / `page[:element_id]`
  class ElementProxy
    def initialize(collector, js_ref)
      @collector = collector
      @js_ref = js_ref
    end

    def replace_html(html)
      @collector << "#{@js_ref}.update(#{LegacyRjs.js_value(html)});"
      self
    end
    alias update replace_html
    alias replace replace_html

    def remove
      @collector << "#{@js_ref}.remove();"
      self
    end

    def method_missing(name, *args, &block)
      if block.nil?
        @collector << "#{@js_ref}.#{name}(#{args.map { |a| LegacyRjs.js_value(a) }.join(', ')});"
        self
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end

  # Proxy for `page.select('#selector')` — behaves like Prototype $$() results.
  class SelectProbe
    def initialize(collector, selector)
      @collector = collector
      @selector = selector
    end

    def each
      body = Collector.new
      yield ItemProxy.new(body)
      @collector << "$$(#{@selector.to_json}).each(function(item){ #{body} });"
      self
    end

    def first
      ItemProxy.new(@collector, "$$(#{@selector.to_json})[0]")
    end
  end

  class ItemProxy
    def initialize(collector, js_ref = 'item')
      @collector = collector
      @js_ref = js_ref
    end

    def replace_html(html)
      @collector << "#{@js_ref}.update(#{LegacyRjs.js_value(html)});"
      self
    end
    alias update replace_html

    def replace(html)
      @collector << "#{@js_ref}.replace(#{LegacyRjs.js_value(html)});"
      self
    end

    def remove
      @collector << "#{@js_ref}.remove();"
      self
    end

    def method_missing(name, *args, &block)
      if block.nil?
        @collector << "#{@js_ref}.#{name}(#{args.map { |a| LegacyRjs.js_value(a) }.join(', ')});"
        self
      else
        super
      end
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end

  class PageRenderer
    attr_reader :collector

    def initialize(controller)
      @controller = controller
      @collector = Collector.new
    end

    # -- element updates ----------------------------------------------------
    def replace_html(selector, content)
      @collector << "#{element_ref(selector)}.update(#{renderable(content)});"
    end
    alias replace replace_html

    def insert_html(position, selector, content)
      klass = { top: 'Top', bottom: 'Bottom', before: 'Before', after: 'After' }[position.to_sym]
      klass ||= position.to_s.capitalize
      @collector << "new Insertion.#{klass}(#{selector.to_s.inspect}, #{renderable(content)});"
    end
    alias insert insert_html

    def remove(selector)
      @collector << "#{element_ref(selector)}.remove();"
    end

    def hide(selector)
      @collector << "#{element_ref(selector)}.hide();"
    end

    def show(selector)
      @collector << "#{element_ref(selector)}.show();"
    end

    def toggle(selector)
      @collector << "#{element_ref(selector)}.toggle();"
    end

    def [](selector)
      ElementProxy.new(@collector, element_ref(selector))
    end

    def select(selector, _options = {})
      SelectProbe.new(@collector, selector)
    end

    # -- effects ------------------------------------------------------------
    def visual_effect(effect, selector, options = {})
      @collector << "new Effect.#{effect.to_s.camelize}(#{selector.to_s.inspect}, #{options.to_json});"
    end
    alias visual_effects visual_effect

    # -- navigation / scripting ---------------------------------------------
    def redirect_to(url)
      @collector << "window.location.href = #{LegacyRjs.js_value(@controller.url_for(url))};"
    end

    def reload
      @collector << 'window.location.reload();'
    end

    def delay(seconds, &block)
      inner = Collector.new
      previous = @collector
      @collector = inner
      yield
      @collector = previous
      @collector << "setTimeout(function(){ #{inner} }, #{seconds.to_i * 1000});"
    end

    def call(function, *args)
      @collector << "#{function}(#{args.map { |a| LegacyRjs.js_value(a) }.join(', ')});"
    end

    def assign(variable, value)
      @collector << "#{variable} = #{LegacyRjs.js_value(value)};"
    end

    def alert(message)
      @collector << "alert(#{LegacyRjs.js_value(message)});"
    end

    def <<(script)
      @collector << script.to_s
    end

    def to_s
      @collector.to_s
    end

    private

    def element_ref(selector)
      s = selector.to_s
      if s.start_with?('#', '.') || s.include?(' ') || s.include?('[')
        "$$(#{s.to_json})[0]"
      else
        "$(#{s.inspect})"
      end
    end

    def renderable(content)
      if content.is_a?(Hash)
        opts = content.dup
        opts[:partial] ||= opts.delete('partial')
        locals = opts.delete(:locals)
        opts[:locals] = locals if locals
        LegacyRjs.js_value(@controller.render_to_string(opts))
      else
        LegacyRjs.js_value(content)
      end
    end
  end

  def self.js_value(value)
    return 'null' if value.nil?
    return value.to_s if value.is_a?(RjsJsRaw) # already-JS

    value.to_s.to_json
  end

  # Marker class for callers that already have JS source (page << "...")
  class RjsJsRaw
    def to_s
      ''
    end
  end

  module Controller
    def render(*args, &block)
      if rjs_update_request?(args)
        render_rjs_update(&block)
      elsif @_legacy_rjs_depth.to_i > 0
        # Nested render inside an RJS block: produce HTML, don't respond.
        render_to_string(*args, &block)
      else
        super
      end
    end

    private

    def rjs_update_request?(args)
      return true if args.first == :update
      return true if args.first.is_a?(Hash) && (args.first.key?(:update) || args.first.key?('update'))

      false
    end

    def render_rjs_update(&block)
      renderer = PageRenderer.new(self)
      @_legacy_rjs_depth = @_legacy_rjs_depth.to_i + 1
      begin
        block.call(renderer) if block
      ensure
        @_legacy_rjs_depth -= 1
      end
      render(plain: renderer.to_s, content_type: 'text/javascript')
    end
  end
end

ActionController::Base.prepend(LegacyRjs::Controller)
