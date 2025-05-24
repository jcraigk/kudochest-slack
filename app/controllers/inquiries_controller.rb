class InquiriesController < ApplicationController
  skip_before_action :require_login
  before_action :use_public_layout

  def new
    @inquiry = Inquiry.new(subject: params[:subject], email: current_profile&.email)
  end

  def create
    @inquiry = Inquiry.new(permitted_params.merge(profile: current_profile))

    if @inquiry.save
      redirect_to new_inquiry_path, notice: t("inquiries.submit_thanks")
    else
      flash[:alert] = t("errors.generic", message: @inquiry.errors.full_messages.to_sentence)
      render :new
    end
  end

  private

  def permitted_params
    params.require(:inquiry).permit(:subject, :body, :email, :phone)
  end
end
