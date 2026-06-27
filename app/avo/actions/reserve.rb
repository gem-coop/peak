class Avo::Actions::Reserve < Avo::BaseAction
  self.name = "Reserve"
  self.visible = -> { true }

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each do |record|
      record.resolve! :reserved, by: current_user
    end
  end
end
