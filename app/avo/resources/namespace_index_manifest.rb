class Avo::Resources::NamespaceIndexManifest < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Index::Manifest
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def display_fields
    field :id, as: :id
    field :author, as: :belongs_to, polymorphic_as: :author, types: [Namespace::Index, Namespace::Index::Cooldown]
    field :contents, as: :textarea
    field :compacted_at, as: :date_time
  end
end
