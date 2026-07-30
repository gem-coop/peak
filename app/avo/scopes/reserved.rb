class Avo::Scopes::Reserved < Avo::Scopes::BaseScope
  self.name = "Reserved"
  # self.description = "Reserved"
  self.scope = :reserved
  self.visible = -> { true }
end
