class Avo::Resources::Namespace < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id,   as: :id
    field :name, as: :text

    field :accesses, as: :has_many
    field :users,    as: :has_many, through: :accesses

    field :external_index, as: :has_one
    field :internal_index, as: :has_one

    field :indexes,  as: :has_many
    field :gems,     as: :has_many, through: :indexes
    field :versions, as: :has_many, through: :gems
  end
end
