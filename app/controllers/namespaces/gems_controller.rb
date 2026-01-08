class Namespaces::GemsController < ApplicationController
  def show
    redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
  end
end
