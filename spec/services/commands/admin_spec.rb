require 'rails_helper'

RSpec.describe Commands::Admin do
  include ActionView::Helpers::NumberHelper

  subject(:command) { described_class.call(team_rid: team.rid, profile_rid: profile.rid) }

  let(:profile) { create(:profile, team:) }
  let(:next_tokens_at) { 1.week.from_now }
  let(:team) do
    create(:team, :with_owner, throttle_tips: true, next_tokens_at:, enable_topics: true)
  end
  let(:response) { ChatResponse.new(mode: :private, text:) }
  let(:text) do
    <<~TEXT.chomp
      *Throttle #{App.points_term}:* Yes
      *Exempt users:* None
      *Token disbursal day:* Monday
      *Token disbursal hour:* 7:00am
      *Token disbursal frequency:* Weekly
      *Token disbursal quantity:* #{team.token_quantity}
      *Token max balance:* #{team.token_max}
      *Topics enabled:* Yes
      *Topic required:* No
      *Active topics:* 0
      *Notes:* Optional
      *#{App.jabs_term.titleize} enabled:* Yes
      *Deduct #{App.jabs_term}:* Yes
      *Emoji enabled:* Yes
      *#{App.points_term.titleize} emoji:* #{team.point_emoj}
      *#{App.jabs_term.titleize} emoji:* #{team.jab_emoj}
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
      *Administrator:* #{team.owner.link} (#{team.owner.email})
    TEXT
  end

  it 'returns stats text' do
    expect(command).to eq(response)
  end
end
