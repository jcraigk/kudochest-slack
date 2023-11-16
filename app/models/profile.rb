class Profile < ApplicationRecord
  include ProfileDecorator
  include Sluggi::Slugged

  enumerize :theme, in: %w[light dark], default: 'light'

  belongs_to :team
  has_many :tips_received,
           class_name: 'Tip',
           foreign_key: :to_profile_id,
           inverse_of: :to_profile,
           dependent: :destroy
  has_many :tips_sent,
           class_name: 'Tip',
           foreign_key: :from_profile_id,
           inverse_of: :from_profile,
           dependent: :destroy
  has_many :subteam_memberships # rubocop:disable Rails/HasManyOrHasOneDependent
  has_many :subteams, through: :subteam_memberships, dependent: :destroy
  has_many :claims, dependent: :destroy
  has_one :owned_team,
          class_name: 'Team',
          foreign_key: :owner_profile_id,
          inverse_of: :owner,
          dependent: :nullify

  attribute :allow_dm,            :boolean, default: true
  attribute :bot_user,            :boolean, default: false
  attribute :deleted,             :boolean, default: false
  attribute :weekly_report,       :boolean, default: false
  attribute :infinite_tokens,     :boolean, default: false
  attribute :points_claimed,      :integer, default: 0
  attribute :points_received,     :integer, default: 0
  attribute :points_sent,         :integer, default: 0
  attribute :jabs_received,       :integer, default: 0
  attribute :jabs_sent,           :integer, default: 0
  attribute :balance,             :integer, default: 0
  attribute :streak_count,        :integer, default: 0
  attribute :tokens,              :integer, default: 0

  alias_attribute :points, :points_received
  alias_attribute :jabs, :jabs_received

  validates :rid, uniqueness: { scope: :team_id }
  validates :avatar_url, presence: true
  validates :display_name, presence: true
  validates :slug, presence: true

  default_scope { includes(:team) }
  scope :active, -> { where(bot_user: false, deleted: false) }
  scope :matching, lambda { |str|
    where('profiles.display_name ILIKE :str OR profiles.real_name ILIKE :str', str: "%#{str}%")
  }

  def self.find_with_team(team_rid, profile_rid)
    joins(:team)
      .where('teams.rid' => team_rid)
      .find_by(rid: profile_rid)
  end

  def active?
    !bot_user && !deleted
  end

  def reset_slug!
    update!(slug: clean_slug(slug_value))
  end

  private

  def slug_candidates
    [base_slug, "#{base_slug}-#{SecureRandom.hex(3)}"]
  end

  def slug_value_changed?
    display_name_changed?
  end

  def base_slug
    "#{team&.slug}-#{display_name}"
  end
end
