class PublicController < ApplicationController
  skip_before_action :require_login
  before_action :set_default_platform
  before_action :use_public_layout

  def cookie_policy; end

  def features; end

  def help; end

  def pricing; end

  def privacy_policy; end

  def terms; end

  private

  def set_default_platform
    session[:platform] ||= :slack
    session[:platform] = params[:platform].to_sym if params[:platform]
    @platform = session[:platform]
  end
end
