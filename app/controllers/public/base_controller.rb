class Public::BaseController < ActionController::Base
  layout "application"

  private
    def set_routed_index_from_user(user)
      set_routed_index from: user.namespaces
    rescue ActiveRecord::RecordNotFound
      render plain: "User doesn't have access to the given namespace", status: :unauthorized
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
