# Enumerate every controller and its own public instance methods (the exact set
# the legacy :controller/:action catch-all would dispatch to).
require 'json'
res = {}
Dir[Rails.root.join('app/controllers/**/*_controller.rb')].each do |f|
  next if f.include?('/concerns/')
  name = f.sub(%r{.*app/controllers/}, '').sub(/_controller\.rb\z/, '')
  next if name == 'application'
  klass = "#{name.camelize}Controller".safe_constantize
  next unless klass && klass < ActionController::Base
  own = klass.instance_methods(false).map(&:to_s)
  acts = (own & klass.action_methods.to_a.map(&:to_s)).sort
  res[name] = acts unless acts.empty?
end
File.write(Rails.root.join('tmp/all_actions.json'), JSON.pretty_generate(res))
puts res.map { |k, v| "#{k}: #{v.join(',')}" }.join("\n")
