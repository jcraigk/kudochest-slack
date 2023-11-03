require 'rails_helper'

RSpec.describe User do
  subject(:user) { build(:user) }

  it { is_expected.to be_a(ApplicationRecord) }

  it { is_expected.to have_one(:profile) }

  it do
    expect(user).to(
      have_one(:owned_team)
        .class_name('Team').with_foreign_key(:owner_user_id)
        .inverse_of(:owner).dependent(:nullify)
    )
  end

  it { is_expected.to have_many(:authentications).dependent(:destroy) }
end
