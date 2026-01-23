class Namespaces::CooldownController < ApplicationController
  def versions
    cv = CooldownVersion.where("created_at < ?", 48.hours.ago).order(:created_at).last
    render plain: CooldownVersion.versions_until(cv&.versions_byte)
  end

  def info
    cv = CooldownVersion.where(name: params[:name]).where("created_at < ?", 48.hours.ago).order(:created_at).last
    render plain: CooldownVersion.info_until(params[:name], cv&.info_byte)
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end
end
