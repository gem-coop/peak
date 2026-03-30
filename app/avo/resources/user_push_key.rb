class Avo::Resources::UserPushKey < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  self.model_class = ::User::PushKey
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  def fields
    field :id, as: :id
    field :token, as: :text, hide_on: :edit
    field :expires_at, as: :date_time
    field :expired?, as: :boolean, hide_on: :forms
    field :user, as: :belongs_to, hide_on: :edit
  end
end
