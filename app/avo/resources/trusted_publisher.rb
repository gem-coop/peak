class Avo::Resources::TrustedPublisher < Avo::BaseResource
  self.model_class = ::TrustedPublisher

  def scopes
    scope Avo::Scopes::PendingPublishers
  end

  def fields
    field :id, as: :id
    field :type, as: :text
    field :gem_name, as: :text
    field :namespace, as: :belongs_to
    field :gem, as: :belongs_to
    field :provider, as: :belongs_to
    field :repository_owner, as: :text
    field :repository_name, as: :text
    field :workflow_filename, as: :text
    field :environment, as: :text
    field :ref, as: :text
    field :created_at, as: :date_time, hide_on: :forms
  end
end
