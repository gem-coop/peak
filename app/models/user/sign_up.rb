class User::SignUp
  mattr_accessor :per_owner_limit, default: 5

  include ActiveModel::Attributes, ActiveModel::Model
  attribute :email_address, Peak::EmailAddress::Type.new
  attr_accessor :name, :namespace_name

  validate { errors.add(:base, "can't sign up using a blocked email domain.") if email_address.blocked_domain? }
  validate { errors.add(:base, "namespace limit reached. contact support for help.") if limit_reached? }

  def save
    submission.save if valid?
  rescue ActiveRecord::RecordNotUnique
    # Race Condition guard: namespace name can be taken after uniqueness constraint checks,
    # so Active Record raises when trying to commit the transaction.
    false
  end

  def limit_reached?
    owner.submissions.limit_reached?(per_owner_limit)
  end

  def submission
    @submission ||= Namespace::Submission.new(name: namespace_name, owner:)
  end

  def owner
    @owner ||= User.create_with(name:).find_or_initialize_by(email_address:)
  end
end
