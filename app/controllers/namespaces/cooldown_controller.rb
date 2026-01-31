class Namespaces::CooldownController < ApplicationController
  def versions
    cv = CooldownVersion.cooled.last
    return no_data unless cv

    Rails.logger.info("curl -X #{request.method} #{curlify_headers(request.headers)} #{request.url}")
    expires_in 30.minutes, public: true
    render_ranged CooldownVersion::Server.versions_until(cv.versions_byte)
  end

  def info
    cv = CooldownVersion.cooled.where(name: params[:name]).last
    return no_data unless cv

    expires_in 30.minutes, public: true
    render_ranged CooldownVersion::Server.info_until(params[:name], cv.info_byte)
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end

  private

  def no_data
    render plain: "Gem dates not yet imported, cannot serve cooldowns", status: 500
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

  def curlify_headers(headers)
    headers.filter { |k, v| k =~ /^HTTP_/ }.map do |k, v|
      "-H \"#{k.gsub(/HTTP_/, '').tr('_', '-').downcase}: #{v}\""
    end.join(" ")
  end
end
