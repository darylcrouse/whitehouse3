module CountFix
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      class << self; prepend CountFix::ClassMethods; end
    end
  end

  module ClassMethods
    def construct_count_options_from_args(*args)
      column_name, options = super(*args)
      column_name = '*' if column_name =~ /\.\*$/
      [column_name, options]
    end
  end
end

ActiveRecord::Base.include(CountFix)