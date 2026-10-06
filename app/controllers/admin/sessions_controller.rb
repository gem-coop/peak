class Admin::SessionsController < ApplicationController
  def create
    github_authenticate!
    redirect_to "/admin/avo"
  end

  def destroy
    github_logout
    redirect_to root_url
  end
end
