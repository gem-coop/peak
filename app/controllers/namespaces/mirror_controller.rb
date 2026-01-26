class Namespaces::MirrorController < ApplicationController
  def versions
    expires_in 5.minutes, public: true
    render plain: CooldownVersion.versions_until(nil)
  end

  def info
    expires_in 5.minutes, public: true
    render plain: CooldownVersion.info_until(params[:name], nil)
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end
end
