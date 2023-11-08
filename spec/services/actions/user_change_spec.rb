require 'rails_helper'

RSpec.describe Actions::UserChange do
  subject(:action) { described_class.call(**params) }

  let(:team) { create(:team) }
  let(:team_rid) { team.rid }
  let(:profile) { create(:profile, team:, display_name: original_display_name) }
  let(:new_display_name) { 'New Display Name' }
  let(:new_real_name) { 'New Real Name' }
  let(:image_url) { 'https://www.example.com' }
  let(:title) { 'My title' }
  let(:email) { 'person@example.com' }
  let(:original_display_name) { 'Alice' }
  let(:curated_params) do
    {
      profile_rid: profile.rid,
      team_rid: team.rid
    }
  end
  let(:slack_params) do
    {
      event: {
        user: {
          id: profile.rid,
          profile: {
            display_name_normalized: new_display_name,
            real_name_normalized: new_real_name,
            title:,
            email:,
            image_512: image_url,
            team: team_rid
          },
          deleted: false,
          is_restricted: restricted,
          is_bot: bot
        }
      }
    }
  end
  let(:restricted) { false }
  let(:bot) { false }
  let(:params) { curated_params.merge(slack_params) }
  let(:expected_attrs) do
    {
      display_name: new_display_name,
      title:,
      email:,
      avatar_url: image_url
    }
  end

  before { allow(TeamSyncWorker).to receive(:perform_async) }

  it 'responds silently' do
    expect(action).to be(true)
    expect(TeamSyncWorker).to have_received(:perform_async).with(team.rid)
  end

  it 'updates the profile' do
    action
    expect(profile.reload.attributes.deep_symbolize_keys).to include(expected_attrs)
  end

  context 'when team is unknown' do
    let(:team_rid) { 'unknown' }

    it 'does not update the user' do
      expect(profile.reload.display_name).not_to eq(new_display_name)
    end
  end

  context 'when display name is not provided' do
    let(:new_display_name) { nil }

    it 'uses real_name_normalized' do
      action
      expect(profile.reload.display_name).to eq(new_real_name)
    end
  end

  context 'when user is restricted' do
    let(:new_display_name) { 'Bob' }
    let(:restricted) { true }

    it 'does not update the profile' do
      action
      expect(profile.reload.display_name).to eq(original_display_name)
    end
  end

  context 'when user is bot' do
    let(:new_display_name) { 'Bob' }
    let(:bot) { true }

    it 'does not update the profile' do
      action
      expect(profile.reload.display_name).to eq(original_display_name)
    end
  end
end
