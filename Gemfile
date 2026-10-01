source "https://rubygems.org"

ruby ">= 3.2.0"

gem "rails", "~> 8.0.2"
gem "sprockets-rails"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 6.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

# --- application domain / historical dependencies (retained & updated) ---
gem "aasm"
gem "acts-as-taggable-on"
gem "acts_as_list"
gem "liquid"
gem "oauth"
gem "auto_html"
gem "RedCloth"
gem "sunlight-congress"
gem "rmagick"
gem "nokogiri"
gem "rss"

group :development do
  gem "web-console"
  gem "pry"
end

group :development, :test do
  gem "debug", platforms: %i[ mri windows jruby ]
end

group :test do
  gem "capybara"
end
