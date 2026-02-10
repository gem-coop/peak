module Peak
  def self.Status(...) = Status.new(...)
  def self.Error(...) = Error.new(...)

  Admin = Data.define :username, :password do
    def authenticate(username_challenge, password_challenge)
      # Use `&` to not short-circuit.
      compare(username, username_challenge) & compare(password, password_challenge)
    end

    def compare(internal, other)
      internal.present? && ActiveSupport::SecurityUtils.secure_compare(internal, other)
    end
  end

  admin = Admin.new(ENV.fetch("ADMIN_USERNAME", "gem-coop"), ENV["ADMIN_PASSWORD"])
  define_singleton_method :admin, &admin.method(:itself)
end
