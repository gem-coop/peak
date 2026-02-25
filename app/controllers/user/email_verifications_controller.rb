class User::EmailVerificationsController < ApplicationController
  def show
    @verification = User::EmailVerification.find_signed!(params[:id])
    @verification.verify

    render Peak::Status("Your email's been verified and you're signed in!")
  end
end
