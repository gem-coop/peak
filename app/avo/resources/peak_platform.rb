class Avo::Resources::PeakPlatform < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Peak::Platform
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :key, as: :text
    field :arch, as: :text
    field :name, as: :text
    field :specifier, as: :text
  end
end
