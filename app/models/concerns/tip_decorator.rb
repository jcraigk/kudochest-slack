module TipDecorator
  extend ActiveSupport::Concern

  def helpers
    ActionController::Base.helpers
  end

  def channel_webref
    name = from_channel_name.presence || "Private"
    helpers.tag.span("#{App.chan_prefix}#{name}", class: "chat-ref")
  end

  def jab?
    quantity.negative?
  end

  def topic_name
    topic&.name || "None"
  end
end
