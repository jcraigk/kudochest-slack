class QuantityValidator < ActiveModel::Validator
  include PointsHelper

  attr_reader :record

  def validate(record)
    @record = record

    return if valid_import?
    return unless zero? || abs_exceeds_max?

    record.errors.add(:quantity, error_msg)
  end

  private

  def error_msg
    <<~TEXT.chomp
      must be less than or equal to #{points_format(team.max_points_per_tip)}
    TEXT
  end

  def abs_exceeds_max?
    record.quantity.abs > max_quantity
  end

  def max_quantity
    team&.max_points_per_tip || App.max_points_per_tip
  end

  def zero?
    record.quantity.zero?
  end

  # Imports are exempt from maximum
  def valid_import?
    record.source.import? && !zero?
  end

  def team
    @team ||= record.from_profile&.team
  end
end
