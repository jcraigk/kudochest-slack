require 'rails_helper'

RSpec.describe Cache::Leaderboard do
  subject(:cache) { described_class.new(team.id, giving_board, jab_board) }

  let(:team) { create(:team) }
  let(:val) { { a: 'a' } }
  let(:key) { "leaderboard/#{team.id}/#{style}/#{action}" }

  shared_examples 'success' do
    describe 'set' do
      before do
        allow(REDIS).to receive(:set)
        cache.set(val)
      end

      it 'calls Rails.cache' do
        expect(REDIS).to have_received(:set).with(key, val.to_json)
      end
    end

    describe 'get' do
      before do
        allow(REDIS).to receive(:get)
        cache.get
      end

      it 'calls Rails.cache' do
        expect(REDIS).to have_received(:get).with(key)
      end
    end
  end

  context 'with default options ("points received")' do
    let(:giving_board) { false }
    let(:jab_board) { false }
    let(:style) { 'points' }
    let(:action) { 'received' }

    it_behaves_like 'success'
  end

  context 'with options for "points sent"' do
    let(:giving_board) { true }
    let(:jab_board) { false }
    let(:style) { 'points' }
    let(:action) { 'sent' }

    it_behaves_like 'success'
  end

  context 'with options for "jabs received"' do
    let(:giving_board) { false }
    let(:jab_board) { true }
    let(:style) { 'jabs' }
    let(:action) { 'received' }

    it_behaves_like 'success'
  end

  context 'with options for "jabs sent"' do
    let(:giving_board) { true }
    let(:jab_board) { true }
    let(:style) { 'jabs' }
    let(:action) { 'sent' }

    it_behaves_like 'success'
  end
end
