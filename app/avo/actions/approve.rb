class Avo::Actions::Approve < Avo::BaseAction
  self.name = "Approve"
  self.visible = -> { true }

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each do |record|
      record.resolve! :approved
      record.process_approved_later
    rescue Namespace::Submission::OwnerEmailUnverifiedError
      error "#{record.name}: owner has not verified their email yet."
    end
  end
end
