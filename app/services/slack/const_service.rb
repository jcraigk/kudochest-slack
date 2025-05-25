class Slack::ConstService < Base::Service
  param :klass

  def call
    "Slack::#{klass}".constantize
  end
end
