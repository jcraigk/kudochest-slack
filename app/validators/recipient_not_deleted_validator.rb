class RecipientNotDeletedValidator < ActiveModel::Validator
  def validate(record)
    return unless record.to_profile&.deleted?
    record.errors.add \
      :base,
      I18n.t(
        "activerecord.errors.models.tip.attributes.base.cannot_tip_deleted",
        user: record.from_profile&.link,
        points: App.points_term
      ).squish
  end
end
