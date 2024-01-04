require 'rails_helper'

RSpec.describe Inquiry do
  subject(:record) { build(:inquiry) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to belong_to(:profile).optional }

  it { is_expected.to validate_presence_of(:body) }

  describe 'sends admin email after creation' do
    let(:mock_mailer) { instance_spy(ActionMailer::MessageDelivery) }

    before do
      allow(InquiryMailer).to receive(:created).with(record).and_return(mock_mailer)
      allow(mock_mailer).to receive(:deliver_later)
      record.save
    end

    it 'calls AdminMailer' do
      expect(mock_mailer).to have_received(:deliver_later)
    end
  end
end
