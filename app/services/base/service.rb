class Base::Service
  extend Dry::Initializer
  include ActionView::Helpers::DateHelper
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::TranslationHelper
  include PointsHelper

  def self.call(...)
    new(...).call
  end
end
