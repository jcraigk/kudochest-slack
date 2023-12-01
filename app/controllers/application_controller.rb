class ApplicationController < ActionController::Base
  include Pundit::Authorization

  protect_from_forgery
  rescue_from Pundit::NotAuthorizedError, with: :not_authorized

  before_action :require_login
  before_action :redirect_oversized_team

  helper_method :current_profile, :current_team

  def login_profile(rid)
    if (profile = Profile.find_by(rid:))&.active?
      create_auth_token(profile)
      true
    else
      cookies.delete(:auth_token)
      false
    end
  end

  def create_auth_token(profile)
    secret = SecureRandom.hex(16)
    update_profile_for_login(profile, secret)
    cookies.permanent.signed[:auth_token] = {
      value: secret,
      httponly: true,
      secure: Rails.env.production?
    }
  end

  def update_profile_for_login(profile, auth_token)
    profile.auth_token = auth_token
    # profile.weekly_report = true if profile.last_login_at.nil? # Slack requires explicit opt-in
    profile.last_login_at = Time.current
    profile.save!
  end

  def redirect_oversized_team
    return if request.path.in? [
      dashboard_path, support_path, cookie_policy_path,
      features_path, help_path, pricing_path, privacy_path, terms_path
    ]
    redirect_to :dashboard if current_team&.oversized?
  end

  def require_login
    return redirect_to root_path, alert: t('auth.login_required') unless current_profile
    return unless current_profile.deleted?
    logout
    redirect_to root_path, alert: t('auth.deleted')
  end

  def pundit_user
    current_profile
  end

  def current_profile
    return @current_profile if defined?(@current_profile)
    return if (auth_token = cookies.signed[:auth_token]).blank?
    @current_profile = Profile.find_by(auth_token:)
  end

  def current_team
    current_profile&.team
  end

  def not_authorized
    flash[:alert] = t('auth.not_authorized')
    redirect_to(request.referer || dashboard_path)
  end

  def fetch_recent_tips(profile)
    received_tips(profile)
      .or(sent_tips(profile))
      .where('created_at >= ?', 100.days.ago)
      .includes(:to_profile, :from_profile, :topic)
      .order(created_at: :desc)
      .page(params[:page] || 1)
  end

  def received_tips(profile)
    Tip.where(to_profile: profile)
  end

  def sent_tips(profile)
    Tip.where(from_profile: profile)
  end

  def build_dashboard_for(profile)
    @leaderboard = LeaderboardPageService.call(profile:)
    @tips = fetch_recent_tips(profile)
    @histogram_data = TipHistogramService.call(profile:, limit: params[:limit])
  end

  def use_public_layout
    @public_layout = true
  end
end
