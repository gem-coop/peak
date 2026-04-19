class Avo::Resources::NamespaceGemCooldownInfo < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::CooldownInfo
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :checksum, as: :text
    field :contents, as: :textarea
    field :envelope, as: :text
    field :gem, as: :belongs_to
    field :cooldown, as: :belongs_to
  end
end
