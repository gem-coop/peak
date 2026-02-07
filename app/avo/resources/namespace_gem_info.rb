class Avo::Resources::NamespaceGemInfo < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Info
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  self.visible_on_sidebar = false

  def fields
    field :id, as: :id
    field :checksum, as: :text
    field :contents, as: :text
    field :envelope, as: :text
    field :gem, as: :belongs_to
  end
end
