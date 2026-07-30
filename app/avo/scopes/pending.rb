class Avo::Scopes::Pending < Avo::Scopes::BaseScope
  self.name = "Pending"
  self.description = "Awaiting approval"
  self.scope = :pending
  self.visible = -> { true }
end
