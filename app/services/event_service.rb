class EventService < Base::Service
  # Allowed action names and their handlers (avoid unsafe constantize)
  ACTION_CLASSES = {
    "AppHomeOpened" => Actions::AppHomeOpened,
    "ChannelSync" => Actions::ChannelSync,
    "Message" => Actions::Message,
    "ReactionAdded" => Actions::ReactionAdded,
    "ReactionRemoved" => Actions::ReactionRemoved,
    "ReplyTip" => Actions::ReplyTip,
    "SubmitPrefsModal" => Actions::SubmitPrefsModal,
    "SubmitTipModal" => Actions::SubmitTipModal,
    "SubteamSync" => Actions::SubteamSync,
    "TeamJoin" => Actions::TeamJoin,
    "TeamRename" => Actions::TeamRename,
    "UserChange" => Actions::UserChange
  }.freeze

  option :params

  def call
    return post_success_message if respond_in_chat?
    delete_slack_ack_message if slack_fast_acked?
  rescue StandardError => e
    post_error_message(e)
  end

  private

  def delete_slack_ack_message
    Slack::Web::Client
      .new(token: params[:config][:api_key])
      .chat_delete(channel: params[:replace_channel_rid], ts: params[:replace_ts])
  end

  def slack_fast_acked?
    params[:replace_channel_rid].present? && params[:replace_ts].present?
  end

  def responder
    @responder ||= Slack::ConstService.call("PostService")
  end

  def post_success_message
    responder.call(**params.merge(result.to_h))
  end

  def result
    @result ||= action_service.call(**params)
  end

  def action_service
    action_name = params[:action].titleize.tr(" ", "")
    self.class::ACTION_CLASSES[action_name]
  end

  def respond_in_chat?
    result.try(:mode).present? && params[:response_mode] != :silent
  end

  def post_error_message(exception)
    log_exception(exception) if Rails.env.development?
    post_chat_error(exception)
  end

  def post_chat_error(exception)
    return if params[:channel_rid].blank? && params[:replace_channel_rid].blank?
    text = ":#{App.error_emoji}: #{error_text(exception)}"
    responder.call(**params.merge(mode: :error, text:))
  end

  def reportable?(exception)
    !exception.is_a?(ActiveRecord::RecordNotUnique) &&
      !exception.is_a?(ActiveRecord::RecordInvalid)
  end

  def error_text(exception)
    return config_dialog_error if config_dialog_error.present?
    exception.instance_of?(ChatFeedbackError) ? exception.message : I18n.t("slack.generic_error")
  end

  def log_exception(exception)
    Rails.logger.info("#{exception.message}\n#{exception.backtrace.join("\n")}")
  end

  def config_dialog_error
    # Preferences dialog must be opened by slash command (Slack requirement since 2022)
    key = :preferences
    command = params[:text]&.split&.last
    return false unless command == key.to_s || command.in?(COMMAND_KEYWORDS[key].map(&:to_s))
    t("errors.config_dialog", command:)
  end
end
