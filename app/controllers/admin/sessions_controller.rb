class Admin::SessionsController < ApplicationController
  def create
    Peak.admin.authenticate request
    redirect_to avo_path
  end

  def destroy
    Peak.admin.logout request
    redirect_to root_url
  end
end
