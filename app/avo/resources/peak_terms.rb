class Avo::Resources::PeakTerms < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Peak::Terms
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def display_fields
    field :id, as: :id
    field :status, as: :select, enum: ::Peak::Terms.statuses
    field(:summary, as: :text) { record.content.truncate(30) }
    field :created_at, as: :date_time
  end

  def form_fields
    field :status, as: :select, enum: ::Peak::Terms.statuses unless record.finalized?
    field :content, as: :textarea if record.new_record?
  end
end
