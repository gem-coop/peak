class Public::BaseController < ActionController::Base
  layout "application"

  private
    def set_routed_index(from: Namespace)
      return head :not_found if params[:index] == "private" # TODO: Figure out routing to the /private index.
      @index = from.approved.named(params[:namespace]).indexes.locate_or_external(params[:index])
    end

    def render_ranged(data)
      response.headers["Accept-Ranges"] = "bytes"
      return render_tagged data unless request.headers["Range"]

      ranges = Rack::Utils.get_byte_ranges(request.headers["Range"], data.length)
      return head(:range_not_satisfiable) if ranges.blank? || ranges.all?(&:blank?)

      range = ranges.first
      slice = data.byteslice(range)
      response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{data.length}"
      response.headers["Content-Length"] = slice.size
      # Ensure the Fly.io edge proxy will not gzip partial responses, breaking content-length
      response.headers["Content-Encoding"] = "none"

      render_tagged slice, status: 206
    end

    def render_tagged(data, status: 200)
      md5 = Digest::MD5.hexdigest(data)
      sha256 = Digest::SHA256.hexdigest(data)
      response.headers["etag"] = %("#{md5}")
      response.headers["digest"] = %(sha256="#{sha256}")
      response.headers["repr-digest"] = %(sha256="#{sha256}")

      render plain: data, status: status
    end
end
