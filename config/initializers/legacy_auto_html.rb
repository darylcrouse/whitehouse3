# frozen_string_literal: false
#
# Legacy `auto_html_for` support.
#
# The application was written against the 2009-era auto_html plugin DSL:
#
#   auto_html_for(:content) do
#     redcloth
#     youtube(:width => 460, :height => 285)
#     vimeo(:width => 460, :height => 260)
#     link(:rel => "nofollow")
#   end
#
# (7 models: document, document_revision, revision, point, message, profile.)
# The modern auto_html gem (2.x) is a pipeline library with no Rails DSL and
# no `auto_html_for`, so this initializer provides the DSL and the four
# filters this application actually uses, writing the rendered result to the
# conventional `#{field}_html` column, exactly like the original plugin did.

module LegacyAutoHtml
  FILTERS = {}

  def self.register(name, &block)
    FILTERS[name.to_sym] = block
  end

  def self.render(text, steps)
    output = text.to_s
    steps.each do |name, options|
      filter = FILTERS[name.to_sym]
      next unless filter

      output = filter.call(output, options || {})
    end
    output
  end

  class ChainBuilder
    attr_reader :steps

    def initialize
      @steps = []
    end

    def method_missing(name, *args)
      @steps << [name, args.first]
      self
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end
  end

  module ModelMacro
    def auto_html_for(field, &block)
      builder = ChainBuilder.new
      builder.instance_eval(&block) if block
      steps = builder.steps.freeze

      define_method(:auto_html_prepare) do
        raw = read_attribute(field)
        self["#{field}_html"] = LegacyAutoHtml.render(raw, steps)
      end

      before_save :auto_html_prepare
    end
  end
end

# --- the filters used by this codebase ---------------------------------------

# Textile rendering (RedCloth) — original semantics preserved.
LegacyAutoHtml.register(:redcloth) do |text, _options|
  begin
    RedCloth.new(text).to_html
  rescue StandardError
    text
  end
end

# YouTube URL -> embed
LegacyAutoHtml.register(:youtube) do |text, options|
  width = options[:width] || 425
  height = options[:height] || 350
  text.gsub(%r{(?:https?://)?(?:www\.)?(?:youtube\.com/watch\?v=|youtu\.be/)([A-Za-z0-9_\-]+)[^\s<"]*}i) do
    video_id = Regexp.last_match(1)
    <<~HTML.strip
      <iframe width="#{width}" height="#{height}" src="https://www.youtube.com/embed/#{video_id}" frameborder="0" allowfullscreen></iframe>
    HTML
  end
end

# Vimeo URL -> embed
LegacyAutoHtml.register(:vimeo) do |text, options|
  width = options[:width] || 425
  height = options[:height] || 350
  text.gsub(%r{(?:https?://)?(?:www\.)?vimeo\.com/(\d+)[^\s<"]*}i) do
    video_id = Regexp.last_match(1)
    <<~HTML.strip
      <iframe width="#{width}" height="#{height}" src="https://player.vimeo.com/video/#{video_id}" frameborder="0" allowfullscreen></iframe>
    HTML
  end
end

# Bare URL -> anchor. Skips URLs already inside href/src attributes.
LegacyAutoHtml.register(:link) do |text, options|
  rel = options && options[:rel]
  rel_attr = rel ? " rel=\"#{rel}\"" : ''
  text.gsub(%r{(?<![\"'=])(https?://[^\s<>\"']+)}i) do |url|
    trimmed = url.sub(/[.,;:!?]+$/, '')
    trailing = url[trimmed.length..] || ''
    "<a href=\"#{trimmed}\"#{rel_attr}>#{trimmed}</a>#{trailing}"
  end
end

ActiveRecord::Base.extend(LegacyAutoHtml::ModelMacro)
