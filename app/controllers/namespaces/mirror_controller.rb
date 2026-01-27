class Namespaces::MirrorController < ApplicationController
  def versions
    redirect_to "https://gem.coop/versions", allow_other_host: true
  end

  def info
    redirect_to "https://gem.coop/info/#{params[:name]}", allow_other_host: true
  end

  def gems
    redirect_to "https://gem.coop/gems/#{params[:gem]}", allow_other_host: true
  end
end
