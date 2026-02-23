class Avo::Resources::NamespaceGemVersionLinking < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Version::Linking
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :version, as: :belongs_to
    field :link, as: :belongs_to
  end
end
