class Avo::Resources::PeakBlockedDomain < Avo::BaseResource
  self.model_class = ::Peak::BlockedDomain
  self.title = :name
  self.search = { query: -> { query.where("name ILIKE ?", "%#{ActiveRecord::Base.sanitize_sql_like(q.to_s)}%") } }

  def fields
    field :id, as: :id
    field :name, as: :text
    field :source, as: :select, enum: ::Peak::BlockedDomain.sources, readonly: true
    field :updated_at, as: :date_time
  end
end
