class User::EmailVerificationsController < ApplicationController
  def show
    @verification = User::EmailVerification.find_signed!(params[:id])
    @verification.verify
    start_new_session_for @verification.user

    # TODO: Set up a user sign in route
    render Peak::Status("Your email's been verified and you're signed in!")
  end

  def start_new_session_for(user)
    reset_session
    cookies.encrypted[:user_id] = user
  end
end
