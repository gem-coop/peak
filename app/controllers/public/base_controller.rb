class Public::BaseController < ActionController::Base
  extend RateLimiting

  layout "application"

  def self.throttle_responses(on:)
    hex = SecureRandom.hex

    # TODO: Replace with this on Rails 8.2:
    # bcrypt = ActiveModel::SecurePassword.lookup_algorithm(:bcrypt)
    # before_action(only: on) { bcrypt.hash_password(hex) }

    cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST : BCrypt::Engine.cost
    before_action(only: on) { BCrypt::Password.create(hex, cost: cost) }
  end

  private
    def set_routed_index_from_user(user)
      set_routed_index from: user.namespaces
    rescue ActiveRecord::RecordNotFound
      render plain: "User doesn't have access to the given namespace", status: :unauthorized
    end

    def set_routed_index(from: Namespace)
      # TODO: Figure out authenticated routing to `private_access` indexes.
      @index = from.named(params[:namespace]).indexes.public_access.locate_or_default(params[:index])
    end

    def stream_lines_from(versions)
      stream_batched versions.latest_last.in_batches(of: 50), &:lines
    end

    def stream_batched(enum)
      writing_occured = false
      enum.each { writing_occured = true; response.stream.write yield it }
    ensure
      response.stream.close if writing_occured
    end
end
