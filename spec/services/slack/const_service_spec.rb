require 'rails_helper'

class Slack::FooService; end # rubocop:disable Lint/EmptyClass

RSpec.describe Slack::ConstService do
  subject(:service) { described_class.call(klass) }

  let(:klass) { "FooService" }

  it 'constantizes the klass under Slack namespace' do
    expect(service).to eq(Slack::FooService)
  end
end
