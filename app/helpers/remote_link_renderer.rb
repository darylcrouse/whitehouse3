# Legacy will_paginate custom renderer (Rails 2 era).
#
# Two views reference `:renderer => 'RemoteLinkRenderer'` when building
# paginated AJAX links. The modernized pagination shim (see
# config/initializers/legacy_support.rb) renders pagination markup directly and
# accepts that option, so this class exists to keep the referenced constant
# loadable (and the views unchanged). If AJAX pagination is reintroduced, wire
# it to the shim's will_paginate helper instead.
class RemoteLinkRenderer
  attr_reader :collection, :options, :template

  def initialize
    @remote = {}
  end

  def prepare(collection, options = {}, template = nil)
    @collection = collection
    @options = options
    @template = template
    @remote = options.delete(:remote) || {}
    self
  end

  def to_html
    return '' unless @template && @collection

    @template.will_paginate(@collection, @options)
  end
end
