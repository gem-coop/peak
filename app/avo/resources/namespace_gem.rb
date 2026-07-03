class Avo::Resources::NamespaceGem < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text, hide_on: :edit

    field :index, as: :belongs_to, hide_on: :edit
    field :namespace, as: :belongs_to, hide_on: :edit

    field :versions, as: :has_many
    field :referrants, as: :has_many
  end
end
