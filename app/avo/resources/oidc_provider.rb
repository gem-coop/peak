class Avo::Resources::OidcProvider < Avo::BaseResource
  self.model_class = ::OIDC::Provider

  def fields
    field :id, as: :id
    field :type, as: :text
    field :name, as: :text
    field :issuer, as: :text
    field :trusted_publishers, as: :has_many
  end
end
