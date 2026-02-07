class Avo::Resources::NamespaceGemVersionReference < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Version::Reference
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :operator_before_type_cast, as: :text
    field :ref, as: :text
    field :nodes, as: :has_many
    field :versions, as: :has_many, through: :nodes
  end
end
