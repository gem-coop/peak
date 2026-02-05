class Avo::Resources::UserPushKey < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::User::PushKey
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :user, as: :belongs_to
    field :token, as: :text
    field :expires_at, as: :date_time
  end
end
