class Avo::Resources::TrustedPublisherPushKey < Avo::BaseResource
  self.model_class = ::TrustedPublisher::PushKey

  def fields
    field :id, as: :id
    field :trusted_publisher, as: :belongs_to
    field :name, as: :text, only_on: :show
    field :expires_at, as: :date_time
    field :created_at, as: :date_time, hide_on: :forms
  end
end
