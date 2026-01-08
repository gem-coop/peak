class Avo::Resources::NamespaceAccess < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Access
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :namespace, as: :belongs_to
    field :user, as: :belongs_to
    field :role, as: :text
  end
end
