class User::SessionsController < ApplicationController
  def show
    magic_link = User::MagicLink.find_signed!(params[:id])
    start_new_session_for(magic_link.user)
    redirect_from_stashed :sign_in
  rescue ActionController::StashedRedirects::MissingRedirectError
    redirect_to root_url
  rescue ActiveSupport::MessageVerifier::InvalidSignature
    redirect_to sign_in_url, alert: "That sign-in link is invalid or has expired. Try again."
  end

  def destroy
    terminate_session
    redirect_to root_url
  end
end
