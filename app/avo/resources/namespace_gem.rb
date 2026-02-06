class Avo::Resources::NamespaceGem < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem
  self.find_record_method = -> { query.named(id) }
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text

    field :index, as: :belongs_to
    field :namespace, as: :belongs_to

    field :info, as: :has_one
    field :trim_versions_published_at, as: :date_time

    field :versions, as: :has_many
    field :referrants, as: :has_many
  end
end
