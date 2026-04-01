class Avo::Resources::PeakTermsAcceptance < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
  # self.includes = []
  # self.attachments = []
  self.model_class = ::Peak::Terms::Acceptance
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def display_fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :terms, as: :belongs_to
    field :user, as: :belongs_to
    field :accepted, as: :boolean
    field :captured_at, as: :date_time
    field :time_zone, as: :text
    field :sha, as: :text
  end
end
