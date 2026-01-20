class Namespaces::GemsController < ApplicationController
  def show
    gem_name, ref = Peak::Gem.version(params[:id])
    version = Namespace.named(params[:namespace]).versions.for(gem_name).find_by!(ref:)

    redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
  end
end
