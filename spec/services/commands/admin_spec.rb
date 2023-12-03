require 'rails_helper'

RSpec.describe Commands::Admin do
  include ActionView::Helpers::NumberHelper

  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:profile) { create(:profile, team:) }
  let(:team) do
    create(:team, :with_owner, throttled: true, throttle_period: 'week', enable_topics: true)
  end
  let(:response) { ChatResponse.new(mode: :private, text:) }
  let(:text) do
    <<~TEXT.chomp
      *Throttle:* #{team.throttle_quantity} #{App.points_term} per #{team.throttle_period}
      *Topics enabled:* Yes
      *Topic required:* No
      *Active topics:* 0
      *Notes:* Optional
      *#{App.jabs_term.titleize} enabled:* Yes
      *Deduct #{App.jabs_term}:* Yes
      *Emoji enabled:* Yes
      *#{App.points_term.titleize} emoji:* #{team.point_emoj}
      *#{App.jab_term.titleize} emoji:* #{team.jab_emoj}
      *Ditto emoji:* #{team.ditto_emoj}
      *Leveling enabled:* Yes
      *Maximum level:* #{team.max_level}
      *Required for max level:* #{points_format(team.max_level_points, label: true)}
      *Progression curve:* Gentle
      *Giving streaks enabled:* Yes
      *Giving streak duration:* #{team.streak_duration} days
      *Giving streak reward:* #{points_format(team.streak_reward, label: true)}
      *Time zone:* (GMT+00:00) UTC
      *Work days:* Monday, Tuesday, Wednesday, Thursday, Friday
      *Administrator:* #{team.owner.link}
    TEXT
  end

  it 'returns stats text' do
    expect(command).to eq(response)
  end
end
