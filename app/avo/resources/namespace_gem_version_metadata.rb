class Avo::Resources::NamespaceGemVersionMetadata < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Version::Metadata
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :version, as: :belongs_to
    field :checksum, as: :text
    field :ruby, as: :text
    field :rubygems, as: :text
  end
end
