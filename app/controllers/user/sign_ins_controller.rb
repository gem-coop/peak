class User::SignInsController < ApplicationController
  rate_limit to: 3, within: 1.minute, with: :rate_limit_response, only: :create
  set_referrer_policy "strict-origin", only: :show

  before_action :verify_confirmation_token_nonce, only: :update
  before_action :set_magic_link, only: %i[edit update]

  def new
    stash_redirect_for :sign_in if redirect_url
  end

  def create
    User::MagicLink.find_by(email_address: params[:email_address])&.deliver_later

    render Peak::Status("Check your email for a sign-in link. Check spam too, just in case.")
  end

  def show
    magic_link = User::MagicLink.find_by_token(params[:token])

    if magic_link && confirmation_token.write(params[:token])
      redirect_to edit_sign_in_index_url
    else
      restart_sign_in
    end
  end

  def edit
  end

  def update
    attempted_access_url = discard_stashed_redirect_for(:sign_in)
    start_new_session_for @magic_link.user
    redirect_to attempted_access_url || dashboard_url
  end

  private
    def rate_limit_response
      render Peak::Error("Too many sign-in attempts. Try again later."), status: :too_many_requests
    end

    def set_magic_link
      @magic_link = confirmation_token.token&.then { User::MagicLink.find_by_token _1 } or restart_sign_in
    end

    def verify_confirmation_token_nonce
      restart_sign_in unless confirmation_token.nonce?(params[:confirmation_nonce])
    end

    def restart_sign_in
      confirmation_token.delete
      redirect_to new_sign_in_url, alert: "That sign-in link is invalid or has expired. Try again."
    end

    def confirmation_token
      @confirmation_token ||= Confirmation::Token[Session::Deref[session, :sign_in_token]]
    end
end
