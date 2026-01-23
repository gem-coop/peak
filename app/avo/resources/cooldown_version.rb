class Avo::Resources::CooldownVersion < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :version, as: :text
    field :published_at, as: :date_time
    field :version_byte, as: :number
    field :info_byte, as: :number
  end
end
