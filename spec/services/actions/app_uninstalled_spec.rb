require 'rails_helper'

RSpec.describe Actions::AppUninstalled, :freeze_time do
  subject(:action) { described_class.call(**params) }

  let!(:team) { create(:team) }

  let(:params) { { team_rid: team.rid } }

  before do
    action
  end

  it 'marks the team uninstalled' do
    expect(team.reload.uninstalled_at).to eq(Time.current)
    expect(team.reload.uninstalled_by).to eq(UNINSTALL_REASONS[:admin])
  end
end
