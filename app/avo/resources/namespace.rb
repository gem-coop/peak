class Avo::Resources::Namespace < Avo::BaseResource
  # self.includes = []
  # self.attachments = []
  # self.search = {
  #   query: -> { query.ransack(id_eq: q, m: "or").result(distinct: false) }
  # }

  self.find_record_method = -> {
    case id
    when Array
      id.first.starts_with?("@") ? query.where(name: id) : query.where(id: id)
    when String
      id.starts_with?("@") ? query.find_by!(name: id) : query.find(id)
    else
      raise "oh no an id we don't know how to handle: #{id.inspect}"
    end
  }

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
    field :created_at,  as: :date_time, hide_on: :forms
    field :approved_at, as: :date_time

    field :accesses, as: :has_many
    field :users,    as: :has_many, through: :accesses

    field :indexes,  as: :has_many
    field :gems,     as: :has_many, through: :indexes
    field :versions, as: :has_many, through: :gems
  end
end
