class Avo::Resources::NamespaceIndex < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Index
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def display_fields
    field :id, as: :id
    field :access, as: :select, enum: ::Namespace::Index.accesses

    field :namespace, as: :belongs_to
    field :gems, as: :has_many
    field :versions, as: :has_many, through: :gems
  end
end
