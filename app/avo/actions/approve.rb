class Avo::Actions::Approve < Avo::BaseAction
  self.name = "Approve"
  self.visible = -> { true }

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each do |record|
      record.adjudiate! :approved, by: current_user
      record.process_approve_later
    end
  end
end
