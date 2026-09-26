class Avo::Resources::Billing::Stripe::Event::Receipt < Avo::BaseResource
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
    field :kind, as: :text
    field :name, as: :text
    field :status, as: :text
    field :data, as: :code
  end
end
