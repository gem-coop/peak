class Avo::Resources::NamespaceGemInfo < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Info
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :gem, as: :belongs_to
    field :contents, as: :textarea
    field :checksum, as: :text
    field :envelope, as: :text
  end
end
