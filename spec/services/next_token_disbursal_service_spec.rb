require 'rails_helper'

RSpec.describe NextTokenDisbursalService do
  subject(:service) { described_class.call(team:) }

  let(:team) do
    create(:team, time_zone: 'Pacific Time (US & Canada)', token_day: :monday, action_hour: 9)
  end

  before { team.update(token_frequency:) }

  context 'when token_frequency is weekly' do
    let(:token_frequency) { 'weekly' }

    it 'calculates time when current hour does not match action_hour and is within tolerance' do
      travel_to Time.zone.local(2022, 12, 31, 10, 0, 0) do
        time_zone = ActiveSupport::TimeZone[team.time_zone]
        # Next Monday 9am since it's within tolerance of 2 days
        expected_time = time_zone.local(2023, 1, 2, 9, 0, 0)
        expect(service).to eq(expected_time)
      end
    end

    it 'calculates time when current hour does not match action_hour and is outside tolerance' do
      travel_to Time.zone.local(2023, 1, 1, 10, 0, 0) do
        time_zone = ActiveSupport::TimeZone[team.time_zone]
        # Next Monday 9am since it's not within tolerance of 2 days
        expected_time = time_zone.local(2023, 1, 9, 9, 0, 0)
        expect(service).to eq(expected_time)
      end
    end

    it 'calculates time when current hour matches team action_hour' do
      travel_to Time.zone.local(2023, 1, 2, team.action_hour, 0, 0) do
        time_zone = ActiveSupport::TimeZone[team.time_zone]
        # Next Monday 9am in exactly 1 week
        expected_time = time_zone.local(2023, 1, 9, team.action_hour, 0, 0)
        expect(service).to eq(expected_time)
      end
    end
  end

  context 'when token_frequency is monthly' do
    let(:token_frequency) { 'monthly' }

    it 'calculates the next monthly token disbursal time' do
      travel_to Time.zone.local(2023, 1, 24, 10, 0, 0) do
        time_zone = ActiveSupport::TimeZone[team.time_zone]
        expected_time = time_zone.local(2023, 2, 27, 9, 0, 0) # First Monday of February
        expect(service).to eq(expected_time)
      end
    end
  end

  context 'when token_frequency is quarterly' do
    let(:token_frequency) { 'quarterly' }

    it 'calculates the next quarterly token disbursal time' do
      travel_to Time.zone.local(2023, 1, 1, 10, 0, 0) do
        time_zone = ActiveSupport::TimeZone[team.time_zone]
        # Next Monday 9am after 3 months has elapsed
        expected_time = time_zone.local(2023, 4, 3, 9, 0, 0)
        expect(service).to eq(expected_time)
      end
    end
  end

  context 'when token_frequency is yearly' do
    let(:token_frequency) { 'yearly' }

    it 'calculates the next yearly token disbursal time' do
      travel_to Time.zone.local(2023, 1, 1, 10, 0, 0) do
        time_zone = ActiveSupport::TimeZone[team.time_zone]
        # Next Monday 9am after a year has elapsed
        expected_time = time_zone.local(2024, 1, 1, 9, 0, 0)
        expect(service).to eq(expected_time)
      end
    end
  end
end
