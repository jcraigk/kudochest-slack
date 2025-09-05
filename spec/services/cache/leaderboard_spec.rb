require 'rails_helper'

RSpec.describe Cache::Leaderboard do
  subject(:cache) { described_class.new(team.id, giving_board, jab_board) }

  let(:team) { create(:team) }
  let(:val) { { a: 'a' } }
  let(:key) { "leaderboard/#{team.id}/#{style}/#{action}" }

  shared_examples 'success' do
    describe 'set_page' do
      let(:page) { 1 }
      let(:profiles) { [ { id: 1, name: 'Test' } ] }
      let(:page_key) { "#{key}/page:#{page}" }

      before do
        allow(REDIS).to receive(:setex)
        cache.set_page(page, profiles)
      end

      it 'calls REDIS.setex with correct args' do
        expect(REDIS).to have_received(:setex).with(page_key, Cache::Leaderboard::PAGE_TTL, profiles.to_json)
      end
    end

    describe 'get_page' do
      let(:page) { 1 }
      let(:page_key) { "#{key}/page:#{page}" }

      before do
        allow(REDIS).to receive(:get).and_return('[]')
        cache.get_page(page)
      end

      it 'calls REDIS.get with correct key' do
        expect(REDIS).to have_received(:get).with(page_key)
      end
    end

    describe 'set_metadata' do
      let(:metadata) { { total_pages: 5, total_profiles: 100 } }
      let(:metadata_key) { "#{key}/metadata" }

      before do
        allow(REDIS).to receive(:setex)
        cache.set_metadata(metadata)
      end

      it 'calls REDIS.setex with correct args' do
        expect(REDIS).to have_received(:setex).with(metadata_key, Cache::Leaderboard::PAGE_TTL, metadata.to_json)
      end
    end

    describe 'get_metadata' do
      let(:metadata_key) { "#{key}/metadata" }

      before do
        allow(REDIS).to receive(:get).and_return('{}')
        cache.get_metadata
      end

      it 'calls REDIS.get with correct key' do
        expect(REDIS).to have_received(:get).with(metadata_key)
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
