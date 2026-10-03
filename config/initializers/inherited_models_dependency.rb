# Load the Liquid droppability concern before any model that calls
# `liquid_methods` at class-body time. Autoloading app constants is not
# allowed while initializers run, so require the file directly and install
# it on ActiveRecord::Base up front (legacy_support's to_prepare re-checks).
require Rails.root.join("app/helpers/liquid_droppable_helper").to_s
ActiveRecord::Base.include(LiquidDroppableHelper) unless ActiveRecord::Base.include?(LiquidDroppableHelper)

require_dependency "activity.rb"
require_dependency "blast.rb" 
require_dependency "relationship.rb"   
require_dependency "capital.rb"