source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.4.3"

gem "aws-sdk-s3"
gem "bulma-rails", "0.9.4" # v1 has breaking changes
gem "chartkick"
gem "csv"
gem "dry-initializer"
gem "enumerize"
gem "factory_bot_rails"
gem "gemoji"
gem "groupdate"
gem "importmap-rails"
gem "jquery-rails"
gem "jwt"
gem "kaminari"
gem "numbers_and_words"
gem "pg"
gem "puma"
gem "pundit"
gem "rails"
gem "redis"
# gem 'rmagick' # TODO: Re-enable graphical responses
gem "sass-rails"
gem "sentry-rails"
gem "sentry-ruby"
gem "sidekiq"
gem "sidekiq-scheduler"
gem "sidekiq-unique-jobs"
gem "slack-ruby-client"
gem "slim"
gem "sluggi"
gem "sprockets-rails", require: "sprockets/railtie"

group :development do
  gem "rubocop-capybara"
  gem "rubocop-factory_bot"
  gem "rubocop-performance"
  gem "rubocop-rails-omakase"
  gem "rubocop-rake"
  gem "rubocop-rspec_rails"
  gem "rubocop-rspec"
  gem "rubocop"
end

group :development, :test do
  gem "bullet"
  gem "dotenv-rails"
  gem "faker"
  gem "webmock"
end

group :test do
  gem "capybara"
  gem "capybara-screenshot"
  gem "rspec-rails"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
  gem "vcr"
end
