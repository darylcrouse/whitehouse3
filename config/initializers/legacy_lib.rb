# frozen_string_literal: false
#
# Legacy library loading.
#
# The original config/environment.rb pulled in a set of hand-rolled libraries
# from lib/ (monkey patches + a couple of parsers). Those files are excluded
# from Zeitwerk management (see config/application.rb autoload_lib ignore)
# and loaded explicitly here, preserving the Rails 2 load order.

require 'timeout'

%w[
  core_extensions
  diff
  sgml_parser
  html2textile
  validates_uri_existence_of
].each do |name|
  path = Rails.root.join('lib', "#{name}.rb")
  require path.to_s if File.exist?(path)
end
