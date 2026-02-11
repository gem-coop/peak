class Avo::Resources::NamespaceGemVersion < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Namespace::Gem::Version
  # self.find_record_method = -> do
  #   gem_name, ref = Peak::Gem.version(id)
  #   query.for(gem_name).find_by(ref:)
  # end
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :ref, as: :text
    field :ruby, as: :text
    field :rubygems, as: :text
    field :executables, as: :code
    field :licenses, as: :code
    field :checksum, as: :text
    field :published_at, as: :date_time

    field :gem, as: :belongs_to
    field :package, as: :file

    field :nodes, as: :has_many
    field :references, as: :has_many, through: :nodes
    field :referrants, as: :belongs_to
  end
end
