class Avo::Actions::Reject < Avo::BaseAction
  self.name = "Reject"
  self.visible = -> { true }

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each do |record|
      record.resolve! :rejected, by: current_user
    end
  end
end
