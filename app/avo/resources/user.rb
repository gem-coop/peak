class Avo::Resources::User < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :email_address, as: :text
    field :accesses, as: :has_many
    field :namespaces, as: :has_many, through: :accesses
    field :push_key, as: :has_one
  end
end
