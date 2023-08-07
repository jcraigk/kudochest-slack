require 'rails_helper'

RSpec.describe QuantityValidator do
  subject(:validate) { described_class.new.validate(tip) }

  let(:team) { build(:team) }
  let(:profile) { build(:profile, team:) }
  let(:tip) { build(:tip, source:, quantity:, from_profile: profile) }
  let(:quantity) { 0 }

  shared_examples 'invalid' do
    let(:error_text) do
      <<~TEXT.chomp
        must be less than or equal to #{team.max_points_per_tip}
      TEXT
    end

    it 'is invalid' do
      validate
      expect(tip.errors[:quantity]).to eq([error_text])
    end
  end

  shared_examples 'valid' do
    it 'is valid' do
      validate
      expect(tip.errors).to be_empty
    end
  end

  context 'when source is import' do
    let(:source) { 'import' }

    context 'when quantity is positive' do
      let(:quantity) { 300 }

      include_examples 'valid'
    end

    context 'when quantity is 0' do
      let(:quantity) { 0 }

      include_examples 'invalid'
    end
  end

  context 'when source is not import' do
    let(:source) { 'inline' }

    context 'when quantity is 0' do
      let(:quantity) { 0 }

      include_examples 'invalid'
    end

    context 'when quantity is 1000' do
      let(:quantity) { 1_000 }

      include_examples 'invalid'
    end

    context 'when quantity is 1' do
      let(:quantity) { 1 }

      include_examples 'valid'
    end
  end
end
