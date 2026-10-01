# The original app (Rails 2 era) keeps its JavaScript and CSS under public/.
# The layouts reference them through the asset helpers, so put those
# directories on the Sprockets load path.
Rails.application.config.assets.paths << Rails.root.join('public', 'javascripts')
Rails.application.config.assets.paths << Rails.root.join('public', 'stylesheets')
Rails.application.config.assets.paths << Rails.root.join('public', 'images')
