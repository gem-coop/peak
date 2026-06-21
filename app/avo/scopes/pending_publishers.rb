class Avo::Scopes::PendingPublishers < Avo::Advanced::Scopes::BaseScope
  self.name = "Pending"
  self.description = "Publishers reserving a not-yet-existing gem"
  self.scope = :pending
  self.visible = -> { true }
end
