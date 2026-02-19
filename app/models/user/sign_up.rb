class User::SignUp
  include ActiveModel::Model
  attr_accessor :name, :email_address, :namespace_name

  def save
    save!
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def save!
    user.transaction do
      user.save!
      namespace.save!
    end
  end

  private
    def user
      @user ||= User.new(name:, email_address:)
    end

    def namespace
      @namespace ||= Namespace.new(name: namespace_name).tap { _1.accesses.owner.new(user:) }
    end
end
