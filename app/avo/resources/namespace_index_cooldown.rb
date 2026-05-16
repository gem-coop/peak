class Avo::Resources::NamespaceIndexCooldown < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Index::Cooldown
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def display_fields
    field :id, as: :id
    field :index, as: :belongs_to
    field :interval, as: :text do
      record.interval.parts
    end
    field :refreshed_at, as: :text
  end
end
