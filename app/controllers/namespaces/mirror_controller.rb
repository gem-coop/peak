class Namespaces::MirrorController < ApplicationController
  def versions
    render plain: CooldownVersion.versions_until(nil)
  end

  def info
    render plain: CooldownVersion.info_until(params[:name], nil)
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end
end
