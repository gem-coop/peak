class Avo::Resources::NamespaceIndex < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Index
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :namespace, as: :belongs_to
    field :versions_blob, as: :belongs_to
    field :access, as: :text
    field :last_compacted_at, as: :date_time
  end
end
