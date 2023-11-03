class User < ApplicationRecord
  extend Enumerize

  authenticates_with_sorcery!

  enumerize :theme, in: %w[light dark], default: 'light'

  has_one :profile, dependent: :destroy
  has_one :owned_team,
          class_name: 'Team',
          foreign_key: :owner_user_id,
          inverse_of: :owner,
          dependent: :nullify
  has_many :authentications, dependent: :destroy

  attribute :admin, :boolean, default: false

  validates :password, length: { minimum: App.password_length }, if: :password
  validates :password, confirmation: true, if: :password
end
