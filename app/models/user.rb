class User < ApplicationRecord
  extend Enumerize

  authenticates_with_sorcery!

  enumerize :theme, in: %w[light dark], default: 'light'

  has_many :profiles, dependent: :destroy
  has_many :owned_teams,
           class_name: 'Team',
           foreign_key: :owner_user_id,
           inverse_of: :owning_user,
           dependent: :nullify
  has_many :authentications, dependent: :destroy

  attribute :admin, :boolean, default: false

  validates :password, length: { minimum: App.password_length }, if: :password
  validates :password, confirmation: true, if: :password
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }

  def owned_team
    owned_teams.first
  end

  def profile
    profiles.first
  end
end
