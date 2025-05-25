require 'rails_helper'

RSpec.shared_context 'with active team' do
  before do
    allow(Cache::TeamConfig).to receive(:call).and_return(
      {
        active: true,
        app_profile_rid: team.app_profile_rid,
        regex: '\+\+'
      }
    )
  end
end
