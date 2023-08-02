# frozen_string_literal: true
class AdminMailer < ApplicationMailer
  def inquiry_created(inquiry)
    @inquiry = inquiry
    mail to: App.admin_email, subject: "Inquiry: #{@inquiry.subject.text}"
  end
end
