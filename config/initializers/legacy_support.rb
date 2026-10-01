# frozen_string_literal: false
#
# Legacy support layer.
#
# This application was written against Rails 2.3 (2009). This file bridges the
# Rails 2.x-era APIs it still uses onto Rails 8 so the ported code can run
# unmodified. Every shim here corresponds to a specific legacy API surface that
# remains in the application code; see the census comments beside each block.
# Shims are additive (defined only when missing) so a future cleanup can delete
# them call-site by call-site.

# ---------------------------------------------------------------------------
# 1. Legacy constants (were provided by config/boot.rb + environment.rb)
#    ~47 call sites across config/, lib/ and app/.
# ---------------------------------------------------------------------------
RAILS_ROOT = Rails.root.to_s unless defined?(RAILS_ROOT)
RAILS_ENV = Rails.env.to_s unless defined?(RAILS_ENV)
RAILS_DEFAULT_LOGGER = Rails.logger unless defined?(RAILS_DEFAULT_LOGGER)

# NB_CONFIG was defined in the original config/environment.rb and is referenced
# by ~25 files (API serialization exclusions).
unless defined?(NB_CONFIG)
  NB_CONFIG = {
    'api_exclude_fields' => [
      :ip_address, :user_agent, :referrer, :google_token, :google_crawled_at,
      :activation_code, :salt, :email, :first_name, :last_name, :crypted_password,
      :is_tagger, :partner_id, :remember_token, :remember_token_expires_at, :zip,
      :birth_date, :city, :state, :is_comments_subscribed, :is_finished_subscribed,
      :is_followers_subscribed, :is_mergeable, :is_messages_subscribed,
      :is_newsletter_subscribed, :is_point_changes_subscribed, :is_votes_subscribed,
      :is_subscribed, :contacts_count, :contacts_invited_count,
      :contacts_members_count, :contacts_not_invited_count, :code, :rss_code, :address
    ]
  }
end

# ---------------------------------------------------------------------------
# 2. Controller filter aliases (Rails 2 vocabulary; ~18 call sites + skips).
# ---------------------------------------------------------------------------
module LegacyFilterAliases
  def before_filter(*args, &block)
    before_action(*args, &block)
  end

  def prepend_before_filter(*args, &block)
    prepend_before_action(*args, &block)
  end

  def append_before_filter(*args, &block)
    before_action(*args, &block)
  end

  def after_filter(*args, &block)
    after_action(*args, &block)
  end

  def prepend_after_filter(*args, &block)
    prepend_after_action(*args, &block)
  end

  def skip_before_filter(*args, &block)
    skip_before_action(*args, raise: false, &block)
  end

  def skip_after_filter(*args, &block)
    skip_after_action(*args, raise: false, &block)
  end
end
ActionController::Base.extend(LegacyFilterAliases)

# Rails 2 `filter_parameter_logging` (removed in Rails 3; parameter filtering
# is global config in modern Rails). No-op shim.
module LegacyParameterFiltering
  def filter_parameter_logging(*args, &block)
    # no-op
  end

  # Rails 2 `verify` macro (removed in Rails 3). Supports the method check +
  # redirect behavior this codebase uses; other check types are ignored.
  def verify(options = {})
    return unless options[:method]

    methods = Array(options[:method]).map { |m| m.to_s.downcase }
    redirect = options[:redirect_to]

    before_action(only: options[:only], except: options[:except]) do
      unless methods.include?(request.method.to_s.downcase)
        if redirect
          redirect_to(redirect)
        else
          head :bad_request
        end
      end
    end
  end
end
ActionController::Base.extend(LegacyParameterFiltering)

# Liquid droppability: models call `liquid_methods` which is provided by the
# app's own LiquidDroppableHelper concern (app/helpers). ~10 models use it.
Rails.application.config.to_prepare do
  unless ActiveRecord::Base.include?(LiquidDroppableHelper)
    ActiveRecord::Base.include(LiquidDroppableHelper)
  end
end

# ---------------------------------------------------------------------------
# 3. Rails 2 finder/count option translation
#    find(:all, :conditions => ...) style — ~208 call sites across the app.
# ---------------------------------------------------------------------------
module LegacyFinders
  LEGACY_FIND_SYMBOLS = %i[all first last].freeze

  def find(*args, &block)
    if args.first.is_a?(Symbol) && LEGACY_FIND_SYMBOLS.include?(args.first)
      kind = args.shift
      options = args.extract_options!
      scope = legacy_scope_from_options(options)
      case kind
      when :all   then scope.to_a
      when :first then scope.first
      when :last  then scope.last
      end
    else
      super
    end
  end

  def count(*args)
    if args.length == 1 && args.first.is_a?(Hash) &&
       (args.first.key?(:conditions) || args.first.key?(:include) || args.first.key?(:joins))
      legacy_scope_from_options(args.first).count
    else
      super
    end
  end

  private

  def legacy_scope_from_options(options)
    options = (options || {}).dup
    scope = all

    conditions = options.delete(:conditions)
    includes   = options.delete(:include)
    joins      = options.delete(:joins)
    select     = options.delete(:select)
    group      = options.delete(:group)
    having     = options.delete(:having)
    from       = options.delete(:from)
    order      = options.delete(:order)
    limit      = options.delete(:limit)
    offset     = options.delete(:offset)
    readonly   = options.delete(:readonly)

    scope = scope.includes(*Array(includes)) if includes
    scope = scope.joins(joins) if joins
    scope = case conditions
            when Array  then scope.where(*conditions)
            when Hash   then scope.where(conditions)
            when String then scope.where(conditions)
            else scope
            end
    scope = scope.select(select) if select
    scope = scope.group(group) if group
    scope = scope.having(having) if having
    scope = scope.from(from) if from
    scope = scope.readonly if readonly
    scope = scope.order(order) if order
    scope = scope.limit(limit) if limit
    scope = scope.offset(offset) if offset
    scope
  end
end
ActiveRecord::Base.singleton_class.prepend(LegacyFinders)
ActiveRecord::Relation.prepend(LegacyFinders)

# ---------------------------------------------------------------------------
# 3a. Dynamic finders removed after Rails 2/3:
#     find_or_create_by_<attrs>, find_or_initialize_by_<attrs>,
#     find_all_by_<attrs> — plus find_by_* calls that pass a trailing
#     options hash (:order => ..., :conditions => ...).
# ---------------------------------------------------------------------------
module LegacyDynamicFinders
  LEGACY_OPTION_KEYS = %i[
    order conditions include joins select group having from limit offset
    readonly
  ].freeze

  def method_missing(name, *args, &block)
    n = name.to_s

    if (m = n.match(/\A(find_or_create_by_|find_or_initialize_by_|find_all_by_)(.+)\z/))
      attrs = m[2].split('_and_')
      options = args.last.is_a?(Hash) ? args.extract_options! : {}
      values = args
      raise ArgumentError, "wrong number of arguments (given #{values.size}, expected #{attrs.size})" if values.size != attrs.size

      scope = values.each_with_index.each_with_object({}) { |(v, i), h| h[attrs[i]] = v }
      relation = all
      if (conds = options[:conditions])
        relation = relation.where(*Array(conds))
      end
      relation = relation.order(options[:order]) if options[:order]

      case m[1]
      when 'find_all_by_'
        relation.where(scope).to_a
      when 'find_or_initialize_by_'
        relation.where(scope).first || new(scope, &block)
      else
        relation.where(scope).first || create(scope, &block)
      end
    elsif n.start_with?('find_by_') && legacy_options_hash?(args.last)
      attrs = n.sub('find_by_', '').split('_and_')
      options = args.extract_options!
      values = args
      raise ArgumentError, "wrong number of arguments (given #{values.size}, expected #{attrs.size})" if values.size != attrs.size

      scope = values.each_with_index.each_with_object({}) { |(v, i), h| h[attrs[i]] = v }
      legacy_scope_from_options(options).where(scope).first
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.match?(/\A(find_or_create_by_|find_or_initialize_by_|find_all_by_)/) || super
  end

  private

  def legacy_options_hash?(obj)
    obj.is_a?(Hash) && !obj.empty? &&
      (obj.keys.map(&:to_sym) & LEGACY_OPTION_KEYS).any?
  end
end
ActiveRecord::Base.singleton_class.prepend(LegacyDynamicFinders)

# ---------------------------------------------------------------------------
# 3b. Bulk operations: Rails 2 passed conditions as a second argument,
#     e.g. Model.update_all(updates, conditions). ~24 call sites.
# ---------------------------------------------------------------------------
module LegacyBulkOperations
  def update_all(updates = nil, conditions = nil, *rest, **kw)
    if conditions
      where(conditions).update_all(updates, *rest, **kw)
    else
      super(updates, *rest, **kw)
    end
  end

  def delete_all(conditions = nil, *rest)
    if conditions
      where(conditions).delete_all
    else
      super(*rest)
    end
  end

  def destroy_all(conditions = nil, *rest)
    if conditions
      where(conditions).destroy_all
    else
      super(*rest)
    end
  end
end
ActiveRecord::Base.extend(LegacyBulkOperations)
ActiveRecord::Base.singleton_class.prepend(LegacyBulkOperations)
ActiveRecord::Relation.prepend(LegacyBulkOperations)

# ---------------------------------------------------------------------------
# 4. Pagination: will_paginate-era API
#    .paginate(:page =>, :per_page =>, :include =>, ...) — ~282 call sites,
#    plus the will_paginate view helper used in ~68 templates.
# ---------------------------------------------------------------------------
module LegacyPagination
  class Page < Array
    attr_reader :current_page, :per_page, :total_entries, :scope

    def initialize(records, current_page, per_page, total_entries, scope = nil)
      super(records)
      @current_page = current_page
      @per_page = per_page
      @total_entries = total_entries
      @scope = scope
    end

    def total_pages
      return 1 if per_page.to_i <= 0
      [(total_entries.to_f / per_page).ceil, 1].max
    end

    def previous_page
      current_page > 1 ? current_page - 1 : nil
    end

    def next_page
      current_page < total_pages ? current_page + 1 : nil
    end

    def first_page?
      current_page <= 1
    end

    def last_page?
      current_page >= total_pages
    end

    def offset
      (current_page - 1) * per_page
    end

    # Kaminari-compatible accessors — parts of the port were rewritten to
    # the Kaminari API (.page(n).per(m)).
    alias_method :total_count, :total_entries
    alias_method :limit_value, :per_page
    alias_method :offset_value, :offset
    alias_method :prev_page, :previous_page

    def out_of_range?
      current_page > total_pages
    end

    def per(num)
      num = num.to_i
      num = per_page if num <= 0
      return self if scope.nil?
      scope.paginate(page: current_page, per_page: num)
    end
  end

  def paginate(options = {})
    options = (options || {}).dup
    page = (options.delete(:page) || 1).to_i
    page = 1 if page < 1
    per_page = options.delete(:per_page)
    unless per_page
      model = respond_to?(:klass) ? klass : self
      per_page = model.per_page if model.respond_to?(:per_page)
    end
    per_page = (per_page || 20).to_i
    per_page = 20 if per_page <= 0

    scope = if respond_to?(:legacy_scope_from_options, true)
              legacy_scope_from_options(options)
            else
              all
            end

    count_scope = scope
    total = count_scope.count
    total = 0 if total.is_a?(Hash) # grouped counts

    records = scope.limit(per_page).offset((page - 1) * per_page).to_a
    Page.new(records, page, per_page, total, scope)
  end

  # Kaminari-style entry point: Model.page(n) / relation.page(n).per(m)
  def page(num = 1)
    num = num.to_i
    num = 1 if num < 1
    paginate(page: num)
  end

  module ViewHelpers
    def will_paginate(collection, options = {})
      return '' if collection.nil?

      current = collection.respond_to?(:current_page) ? collection.current_page : 1
      total_pages = collection.respond_to?(:total_pages) ? collection.total_pages : 1
      return '' if total_pages <= 1

      window = 4
      first = [current - window, 1].max
      last = [current + window, total_pages].min

      links = []
      if current > 1
        links << page_link(options, current - 1, t('pagination.previous', default: '&laquo; Previous'))
      end
      (first..last).each do |n|
        links << if n == current
                   content_tag(:em, n.to_s)
                 else
                   page_link(options, n, n.to_s)
                 end
      end
      if current < total_pages
        links << page_link(options, current + 1, t('pagination.next', default: 'Next &raquo;'))
      end

      content_tag(:div, safe_join(links, ' '), class: 'pagination')
    end

    # Views call both will_paginate and paginate (will_paginate's view helper
    # was commonly aliased as `paginate`). Extra options (:renderer, :params,
    # :class, :inner_window, ...) are accepted and ignored by this shim.
    alias_method :paginate, :will_paginate

    def page_entries_info(collection)
      return '' unless collection.respond_to?(:total_entries)
      "#{collection.offset + 1} - #{collection.offset + collection.size} of #{collection.total_entries}"
    end

    private

    def page_link(options, n, label)
      params = request.params.except(:controller, :action, :format).merge(page: n)
      link_to(label.html_safe, url_for(params))
    end
  end
end
ActiveRecord::Relation.include(LegacyPagination)
ActiveRecord::Base.extend(LegacyPagination) if defined?(ActiveRecord::Base)

# Legacy controllers call `.paginate` on plain Arrays (the result of legacy
# `find(:all, ...)` shims), which will_paginate used to provide.
module LegacyArrayPagination
  def paginate(options = {})
    options = (options || {}).dup
    page = (options.delete(:page) || 1).to_i
    page = 1 if page < 1
    per_page = (options.delete(:per_page) || 20).to_i
    per_page = 20 if per_page <= 0
    total = size
    records = self[(page - 1) * per_page, per_page] || []
    LegacyPagination::Page.new(records, page, per_page, total)
  end
end
Array.include(LegacyArrayPagination) unless Array.method_defined?(:paginate)

ActiveSupport.on_load(:action_view) do
  include LegacyPagination::ViewHelpers
end

# ---------------------------------------------------------------------------
# 5b. Rails 2 view helper error_messages_for (removed in Rails 3).
# ---------------------------------------------------------------------------
module LegacyErrorMessagesHelper
  def error_messages_for(*params)
    options = params.extract_options!.symbolize_keys
    objects = params.flat_map do |name|
      if name.is_a?(String) || name.is_a?(Symbol)
        [instance_variable_get("@#{name}")]
      else
        [name]
      end
    end.compact

    messages = objects.select { |o| o.respond_to?(:errors) && o.errors.respond_to?(:full_messages) }
                      .flat_map { |o| o.errors.full_messages }
                      .uniq
    return ''.html_safe if messages.empty?

    header = options[:header_message] ||
             "#{messages.size} #{messages.size == 1 ? 'error' : 'errors'} prohibited this from being saved"
    body = options[:message] || 'There were problems with the following fields:'
    items = safe_join(messages.map { |m| content_tag(:li, m) })
    content_tag(:div,
                content_tag(:h2, header) + content_tag(:p, body) + content_tag(:ul, items),
                id: options[:id], class: options[:class] || 'errorExplanation')
  end
end
ActiveSupport.on_load(:action_view) do
  include LegacyErrorMessagesHelper
end

# Rails 2's FormBuilder offered `f.error_messages` (used by ~30 templates).
# Recreate it on the modern builder, delegating the markup to the
# error_messages_for helper above.
ActionView::Helpers::FormBuilder.class_eval do
  def error_messages(options = {})
    object = @object
    return ''.html_safe if object.nil? || !object.respond_to?(:errors) || object.errors.empty?

    messages = object.errors.full_messages
    header = options[:header_message] ||
             "#{messages.size} #{messages.size == 1 ? 'error' : 'errors'} prohibited this " \
             "#{object.class.model_name.human.downcase} from being saved"
    body = options[:message] || 'There were problems with the following fields:'
    items = @template.safe_join(messages.map { |m| @template.content_tag(:li, m) })
    @template.content_tag(:div,
                          @template.content_tag(:h2, header) +
                          @template.content_tag(:p, body) +
                          @template.content_tag(:ul, items),
                          id: options[:id] || 'errorExplanation',
                          class: options[:class] || 'errorExplanation')
  end
end

# ---------------------------------------------------------------------------
# 5c. flash_div — from the flash_message plugin (Rails 2 era), used by the
#     layouts. Class names match the stylesheets (.flash_notice etc).
# ---------------------------------------------------------------------------
module LegacyFlashHelper
  def flash_div(*keys)
    divs = keys.flatten.filter_map do |key|
      message = flash[key.to_sym]
      content_tag(:div, message, class: "flash_#{key}") if message.present?
    end
    safe_join(divs)
  end

  # Prototype-era observing helpers (removed with the prototype helpers in
  # Rails 3); the app's jQuery code handles these interactions now.
  def observe_form(*_args)
    ''
  end

  def observe_field(*_args)
    ''
  end

  # Scriptaculous helpers. The sortable/draggable UI was Prototype-based;
  # templates still call the helpers, so render nothing rather than crash.
  def sortable_element(*_args)
    ''
  end

  def draggable_element(*_args)
    ''
  end

  def drop_receiving_element(*_args)
    ''
  end

  def periodically_call_remote(*_args)
    ''
  end

  # Prototype's form_remote_tag opened the form by writing directly into the
  # output buffer (called with `<%`, not `<%=`). Modern templates use `<%=`
  # and get a regular form back; non-GET/POST methods degrade to a hidden
  # _method field, so submissions still work without Prototype in the page.
  def form_remote_tag(options = {}, &block)
    options = (options || {}).dup
    url = options.delete(:url) || {}
    html = options.delete(:html) || {}
    method = (options.delete(:method) || :post).to_s
    form_tag(url, html.merge(method: method)) { capture(&block) }
  end
end
ActiveSupport.on_load(:action_view) do
  include LegacyFlashHelper
end

# ---------------------------------------------------------------------------
# 5. Model persistence aliases
#    save_with_validation(false) ~79 call sites; positional save(false).
# ---------------------------------------------------------------------------
module LegacyPersistence
  def save(*args, **kwargs, &block)
    kwargs[:validate] = args.first if [true, false].include?(args.first)
    super(**kwargs, &block)
  end

  def save!(*args, **kwargs, &block)
    kwargs[:validate] = args.first if [true, false].include?(args.first)
    super(**kwargs, &block)
  end

  def save_with_validation(perform_validation = true)
    save(validate: perform_validation)
  end

  def save_with_validation!(perform_validation = true)
    save!(validate: perform_validation)
  end
end
ActiveRecord::Base.include(LegacyPersistence)

# will_paginate historically provided a `per_page` attribute on models
# (models assign it directly, e.g. `self.per_page = 25`).
unless ActiveRecord::Base.respond_to?(:per_page)
  class ActiveRecord::Base
    class_attribute :per_page, instance_accessor: true, default: 20
  end
end

unless ActiveRecord::Base.method_defined?(:update_attributes)
  module LegacyUpdateAttributes
    def update_attributes(attributes)
      update(attributes)
    end

    def update_attributes!(attributes)
      update!(attributes)
    end
  end
  ActiveRecord::Base.include(LegacyUpdateAttributes)
end

# ---------------------------------------------------------------------------
# 6. Class-level attribute accessors (cattr_reader — 10 call sites, used with
#    @@class_variable backing, e.g. @@per_page = 25, and class-level writers,
#    e.g. self.per_page = 25).
# ---------------------------------------------------------------------------
class Module
  unless method_defined?(:cattr_reader)
    def cattr_reader(*syms)
      syms.each do |sym|
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def self.#{sym}; @@#{sym}; end
          def #{sym}; @@#{sym}; end
        RUBY
      end
    end
  end

  unless method_defined?(:cattr_writer)
    def cattr_writer(*syms)
      syms.each do |sym|
        class_eval(<<-RUBY, __FILE__, __LINE__ + 1)
          def self.#{sym}=(value); @@#{sym} = value; end
          def #{sym}=(value); @@#{sym} = value; end
        RUBY
      end
    end
  end

  unless method_defined?(:cattr_accessor)
    def cattr_accessor(*syms)
      cattr_reader(*syms)
      cattr_writer(*syms)
    end
  end

  # Legacy code also writes through cattr_reader-only declarations
  # (e.g. `cattr_reader :per_page` + `self.per_page = 25`), matching Rails 2
  # behavior where the class variable was freely writable.
  unless method_defined?(:cattr_reader_with_writer)
    alias_method :cattr_reader_with_writer, :cattr_reader
    def cattr_reader(*syms, **kw)
      cattr_reader_with_writer(*syms, **kw)
      syms.each do |sym|
        next unless sym.to_s =~ /\A[_A-Za-z]\w*\z/
        class_eval("def self.#{sym}=(value); @@#{sym} = value; end", __FILE__, __LINE__)
      end
    end
  end
end

# ---------------------------------------------------------------------------
# 7. Mass-assignment: the original app relied on attr_accessible/attr_protected
#    which modern Rails replaced with strong parameters. ~Every create/update
#    call in this codebase passes params hashes directly.
#    NOTE: this preserves legacy behavior; tightening to strong parameters is
#    tracked as follow-up work.
# ---------------------------------------------------------------------------
ActionController::Parameters.permit_all_parameters = true

# ---------------------------------------------------------------------------
# 8. request.request_uri (Rails 2) — 4 call sites.
# ---------------------------------------------------------------------------
unless ActionDispatch::Request.method_defined?(:request_uri)
  ActionDispatch::Request.class_eval do
    def request_uri
      fullpath
    end
  end
end

# ---------------------------------------------------------------------------
# 9. acts_as_solr (dead Solr integration, 1 model + initializer).
#    Neutralize the macro and back find_by_solr with a pragmatic SQL search.
# ---------------------------------------------------------------------------
module LegacySolr
  def acts_as_solr(*args)
    # no-op: indexing disabled; search falls back to SQL (see find_by_solr)
  end
  def find_by_solr(query, options = {})
    limit = options[:limit] || 20
    terms = query.to_s
                 .gsub(/[()]/, ' ')
                 .gsub(/\b\w+:\S+/, ' ')
                 .scan(/[\w'@.-]+/)
                 .reject { |w| %w[and or not AND OR NOT].include?(w) }
                 .first(6)

    scope = all
    terms.each do |term|
      columns = %w[name content]
      columns.select! { |c| column_names.include?(c) }
      if columns.empty?
        columns = [primary_key]
      end
      clause = columns.map { |c| "#{table_name}.#{c} LIKE :q" }.join(' OR ')
      scope = scope.where(clause, q: "%#{term}%")
    end
    scope.limit(limit).to_a
  end
end
ActiveRecord::Base.extend(LegacySolr)

# ---------------------------------------------------------------------------
# 10. Delayed::Job (delayed_job plugin API) — enqueue/get/worker.
#     Backed by the existing delayed_jobs table + DelayedJob model.
# ---------------------------------------------------------------------------
require 'yaml'

Rails.application.config.to_prepare do
  module Delayed
    class Job < ::DelayedJob
      def self.enqueue(object, priority = 0, run_at = nil)
        run_at = Time.zone.now if run_at.nil?
        create!(
          priority: priority,
          run_at: run_at,
          handler: YAML.dump(object),
          attempts: 0
        )
      end

      def payload
        YAML.unsafe_load(handler)
      rescue StandardError
        nil
      end

      def invoke_job
        object = payload
        object.perform if object.respond_to?(:perform)
      end
    end

    class Worker
      def work_off(limit = 25)
        processed = 0
        jobs = Job.where(failed_at: nil).where('run_at <= ?', Time.zone.now)
                  .order(Arel.sql('priority ASC, run_at ASC')).limit(limit)
        jobs.each do |job|
          begin
            job.invoke_job
            job.destroy
          rescue StandardError => e
            job.update_columns(last_error: e.message.to_s,
                               attempts: job.attempts.to_i + 1,
                               run_at: 5.minutes.from_now)
          end
          processed += 1
        end
        processed
      end
    end
  end
end
