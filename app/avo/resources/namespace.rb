class Avo::Resources::Namespace < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  # def find_record(id)
  #   named(id)
  # end

  self.find_record_method = -> { query.where(name: id) }

  def scopes
    scope Avo::Scopes::Pending
    scope Avo::Scopes::Approved
  end

  def actions
    action Avo::Actions::Approve, icon: "heroicons/outline/check-circle"
  end

  def fields
    field :id,   as: :id
    field :name, as: :text
    field :approved_at, as: :date_time

    field :accesses, as: :has_many
    field :users,    as: :has_many, through: :accesses

    field :external_index, as: :has_one
    field :dev_index, as: :has_one
    field :private_index, as: :has_one

    field :indexes,  as: :has_many
    field :gems,     as: :has_many, through: :indexes
    field :versions, as: :has_many, through: :gems
  end
end
