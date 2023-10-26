class Hooks::BaseController < ActionController::Base # rubocop:disable Rails/ApplicationController
  skip_forgery_protection
end
