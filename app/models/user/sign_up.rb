class User::SignUp
  include ActiveModel::Model
  attr_accessor :name, :email_address, :namespace_name

  def save
    access.save if user.valid? && namespace.valid?
  rescue ActiveRecord::RecordNotUnique
    # Race Condition guard: the email_address or namespace name can be taken after uniqueness constraint checks,
    # so Active Record raises when trying to commit the transaction.
    false
  end

  def access
    @access ||= Namespace.new(name: namespace_name).then do
      _1.accesses.owner.new user: User.new(name:, email_address:)
    end
  end
  delegate :user, :namespace, to: :access
end
