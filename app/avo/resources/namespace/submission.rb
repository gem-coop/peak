class Avo::Resources::Namespace::Submission < Avo::BaseResource
  # self.icon = "tabler/outline/users"
  # self.avatar = {
  #   source: :avatar
  # }
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
    scope Avo::Scopes::Reserved
    scope Avo::Scopes::Rejected
  end

  def actions
    if view.show? && !record.approved?
      action Avo::Actions::Approve, icon: "heroicons/outline/check-circle"
      divider

      action Avo::Actions::Reserve, icon: "heroicons/outline/archive-box-arrow-down"
      action Avo::Actions::Reject, icon: "heroicons/outline/archive-box-x-mark"
    end
  end

  def fields
    field :id, as: :id
    # field :avatar, as: :avatar
    field :owner, as: :belongs_to
    field :name, as: :text
    field :status, as: :text
    field :resolved_at, as: :date_time
  end
end
