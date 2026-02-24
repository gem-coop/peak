class Avo::Scopes::Approved < Avo::Advanced::Scopes::BaseScope
  self.name = "Approved"
  # self.description = "Approved"
  self.scope = :approved
  self.visible = -> { true }
end
