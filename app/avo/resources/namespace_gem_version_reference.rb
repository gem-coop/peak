class Avo::Resources::NamespaceGemVersionReference < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Version::Reference
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :source, as: :belongs_to
    field :linked, as: :belongs_to
    field :operator, as: :text
  end
end
