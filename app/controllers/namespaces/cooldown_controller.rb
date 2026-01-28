class Namespaces::CooldownController < ApplicationController
  def versions
    cv = CooldownVersion.cooled.last
    return no_data unless cv

    expires_in 30.minutes, public: true

    if request.headers["Range"]
      ranges = Rack::Utils.get_byte_ranges(request.headers["Range"], cv.versions_byte)
      range = ranges.first
      data = CooldownVersion::Server.versions_until(cv.versions_byte)
      response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{cv.versions_byte}"
      response.headers["Accept-Ranges"] = "bytes"
      response.headers["Content-Length"] = data.length.to_s

      send_data data.byteslice(range.begin, range.end), status: 206
    else
      send_data CooldownVersion::Server.versions_until(cv.versions_byte)
    end
  end

  def info
    cv = CooldownVersion.cooled.where(name: params[:name]).last
    return no_data unless cv

    expires_in 30.minutes, public: true

    if request.headers["Range"]
      ranges = Rack::Utils.get_byte_ranges(request.headers["Range"], cv.info_byte)
      range = ranges.first
      data = CooldownVersion::Server.versions_until(cv.versions_byte)
      response.headers["Content-Range"] = "bytes #{range.begin}-#{range.end}/#{cv.versions_byte}"
      response.headers["Accept-Ranges"] = "bytes"
      response.headers["Content-Length"] = data.length.to_s
      send_data data.byteslice(range.begin, range.end), status: 206
    else
      render plain: CooldownVersion::Server.info_until(params[:name], cv.info_byte)
    end
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end

  private

  def no_data
    render plain: "Gem dates not yet imported, cannot serve cooldowns", status: 500
  end
end
