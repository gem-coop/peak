class Avo::Scopes::Rejected < Avo::Scopes::BaseScope
  self.name = "Rejected"
  # self.description = "Rejected"
  self.scope = :rejected
  self.visible = -> { true }
end
