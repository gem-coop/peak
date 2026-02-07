class Avo::Resources::NamespaceAccess < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Access
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :namespace, as: :belongs_to, hide_on: :edit
    field :user, as: :belongs_to, hide_on: :edit
    field :role, as: :select, enum: ::Namespace::Access.roles
  end
end
