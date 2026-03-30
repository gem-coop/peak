class User::SessionsController < ApplicationController
  resume_authenticated

  def destroy
    terminate_session
    redirect_to root_url
  end
end
