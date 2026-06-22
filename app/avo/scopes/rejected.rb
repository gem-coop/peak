class Avo::Scopes::Rejected < Avo::Advanced::Scopes::BaseScope
  self.name = "Rejected"
  # self.description = "Rejected"
  self.scope = :rejected
  self.visible = -> { true }
end
