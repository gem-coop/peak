class Public::BaseController < ActionController::Base
  layout "application"

  def self.throttle_responses(on:, duration: 0.3.seconds)
    before_action(only: on) { Throttle.call(duration) }
  end

  module Throttle
    mattr_accessor :handler, default: Rails.env.test? ? nil : -> { sleep _1 }
    singleton_class.delegate :call, to: :handler, allow_nil: true

    def self.apply(duration: 0.1.seconds, &)
      with(handler: proc { sleep duration }, &)
    end
  end

  private
    def set_routed_index_from_user(user)
      set_routed_index from: user.namespaces
    rescue ActiveRecord::RecordNotFound
      render plain: "Namespace is not approved or user doesn't have access to it", status: :unauthorized
    end

    def set_routed_index(from: Namespace)
      # TODO: Figure out authenticated routing to `private_access` indexes.
      @index = from.approved.named(params[:namespace]).indexes.public_access.locate_or_default(params[:index])
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
