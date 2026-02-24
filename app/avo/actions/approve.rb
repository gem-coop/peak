class Avo::Actions::Approve < Avo::BaseAction
  self.name = "Approve"
  self.visible = -> { true }

  # def fields
  #   # Add Action fields here
  # end

  def handle(query:, fields:, current_user:, resource:, **args)
    query.each(&:approve)
  end
end
