require 'rails_helper'

RSpec.describe Commands::Preferences do
  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:team) { create(:team) }
  let(:profile) { create(:profile, team:) }
  let(:response) { ChatResponse.new(mode: :prefs_modal) }

  it 'returns stats text' do
    expect(command).to eq(response)
  end
end
