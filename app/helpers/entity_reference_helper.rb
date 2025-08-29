module EntityReferenceHelper
  def helpers
    ActionController::Base.helpers
  end

  def channel_link(rid)
    "<#{App.chan_prefix}#{rid}>"
  end

  def channel_webref(name)
    helpers.tag.span("#{App.chan_prefix}#{name}", class: "chat-ref")
  end

  def subteam_webref(name)
    helpers.tag.span(name, class: "chat-ref")
  end
end
