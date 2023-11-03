require 'rails_helper'

RSpec.shared_examples 'TeamSyncService', :freeze_time do
  subject(:service) { described_class.call(team:, first_run:) }

  let(:team) { create(:team, api_key: 'api-key') }
  let!(:existing_profile) { create(:profile, team:, rid: 'existing-rid') }
  let!(:extra_profile) { create(:profile, team:, display_name: 'Extra') }
  let(:display_names) { team.profiles.active.order(display_name: :asc).map(&:display_name) }
  let(:first_run) { false }
  let(:mailer_double) { instance_double(ActionMailer::MessageDelivery, deliver_later: true) }

  context 'when team is oversized' do
    before do
      allow(App).to receive(:max_team_size).and_return(2)
      allow(team).to receive(:uninstall!)
      service
    end

    it 'uninstalls' do
      expect(team).to have_received(:uninstall!).with('Team exceeds maximum size')
    end
  end

  context 'when team is not oversized' do
    before do
      allow(SubteamSyncWorker).to receive(:perform_async)
      allow(TokenDispersalService).to receive(:call)
      allow(OnboardingMailer).to receive(:welcome).and_return(mailer_double)
      service
    end

    it 'updates team.member_count' do
      expect(team.member_count).to eq(5)
    end

    it 'creates profiles' do
      expect(display_names).to eq(expected_names)
    end

    it 'updates existing profiles' do
      expect(existing_profile.reload.display_name).to eq('Existing')
    end

    it 'marks extra profiles as deleted' do
      expect(extra_profile.reload.deleted).to be(true)
    end

    it 'updates team.app_profile_rid' do
      expect(team.app_profile_rid).to eq('app-profile-rid')
    end

    it 'assigns `bot_user`' do
      expect(team.profiles.where(bot_user: true).size).to eq(1)
    end

    it 'invokes SubteamSyncWorker' do
      expect(SubteamSyncWorker).to have_received(:perform_async).with(team.rid)
    end

    context 'when first_run is true (initial team sync)' do
      let(:first_run) { true }

      it 'calls TokenDispersalService without notifications' do
        expect(TokenDispersalService).to have_received(:call).with(team:, notify: false)
      end

      it 'calls OnboardingMailer.welcome' do
        expect(OnboardingMailer).to have_received(:welcome)
      end
    end

    xcontext 'when a user has an active authentication' do
      it 'auto associates the profiles to the user' do
      end
    end
  end
end
