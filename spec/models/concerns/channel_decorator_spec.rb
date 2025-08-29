require 'rails_helper'

RSpec.describe ChannelDecorator do
  subject(:channel) { build(:channel) }

  describe '#link' do
    it 'returns expected text' do
      expect(channel.link).to eq("<#{App.chan_prefix}#{channel.rid}>")
    end
  end

  describe '#webref' do
    it 'returns expected text' do
      expect(channel.webref).to eq("<span class=\"chat-ref\">#{App.chan_prefix}#{channel.name}</span>")
    end
  end
end
