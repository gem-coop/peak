class User::SignUp
  include ActiveModel::Model
  attr_accessor :name, :email_address, :namespace_name

  def save
    owner.valid? && submission.save
  rescue ActiveRecord::RecordNotUnique
    # Race Condition guard: the email_address or namespace name can be taken after uniqueness constraint checks,
    # so Active Record raises when trying to commit the transaction.
    false
  end

  def submission
    @submission ||= Namespace::Submission.new(name: namespace_name, owner: User.new(name:, email_address:))
  end
  delegate :owner, to: :submission
end
