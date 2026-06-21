class Avo::Resources::OidcIdToken < Avo::BaseResource
  self.model_class = ::OIDC::IdToken

  def fields
    field :id, as: :id
    field :jti, as: :text
    field :provider, as: :belongs_to
    field :trusted_publisher, as: :belongs_to
    field :push_key, as: :belongs_to
    field :claims, as: :code, language: "json"
    field :created_at, as: :date_time
  end
end
