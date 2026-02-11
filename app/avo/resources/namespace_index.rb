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
    field :last_compacted_at, as: :date_time
    # field :versions_contents, as: :text # TODO: Output this potentially large field? Not sure.

    field :namespace, as: :belongs_to
    field :gems, as: :has_many
    field :infos, as: :has_many, through: :gems
    field :versions, as: :has_many, through: :gems
  end
end
