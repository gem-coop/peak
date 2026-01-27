class Namespaces::CooldownController < ApplicationController
  def versions
    cv = CooldownVersion.cooled.last
    return no_data unless cv

    expires_in 30.minutes, public: true
    render plain: CooldownVersion::Server.versions_until(cv.versions_byte)
  end

  def info
    cv = CooldownVersion.cooled.where(name: params[:name]).last
    return no_data unless cv

    expires_in 30.minutes, public: true
    render plain: CooldownVersion::Server.info_until(params[:name], cv.info_byte)
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end

  private

  def no_data
    render plain: "Gem dates not yet imported, cannot serve cooldowns", status: 500
  end
end
