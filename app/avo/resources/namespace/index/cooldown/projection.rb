class Avo::Resources::Namespace::Index::Cooldown::Projection < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :cooldown, as: :belongs_to
    field :version, as: :belongs_to
    field :append_at, as: :date_time
  end
end
