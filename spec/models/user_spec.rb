require 'rails_helper'

RSpec.describe User do
  subject(:user) { build(:user) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to have_many(:profiles) }

  it do
    expect(user).to(
      have_many(:owned_teams)
        .class_name('Team').with_foreign_key(:owner_user_id)
        .inverse_of(:owning_user).dependent(:nullify)
    )
  end

  it { is_expected.to have_many(:authentications).dependent(:destroy) }

  it { is_expected.to validate_length_of(:password).is_at_least(App.password_length) }
  it { is_expected.to validate_confirmation_of(:password) }
  it { is_expected.to validate_uniqueness_of(:email) }
  it { is_expected.to allow_value('not an email address').for(:password) }
  it { is_expected.to allow_value('email@example.com').for(:password) }

  it { accept_nested_attributes_for(:authentications) }
end
