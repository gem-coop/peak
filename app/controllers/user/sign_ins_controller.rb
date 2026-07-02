class User::SignInsController < ApplicationController
  rate_limit to: 3, within: 1.minute, with: :rate_limit_response, only: :create
  set_referrer_policy "strict-origin", only: :show

  before_action :set_magic_link, only: :show
  before_action :set_pending_magic_link, only: %i[confirm update]
  before_action :verify_confirmation_nonce, only: :update

  def new
    stash_redirect_for :sign_in if redirect_url
  end

  def create
    User::MagicLink.find_by(email_address: params[:email_address])&.deliver_later

    render Peak::Status("Check your email for a sign-in link. Check spam too, just in case.")
  end

  def show
    stash_pending_sign_in params[:token]
    redirect_to confirm_sign_in_index_url
  end

  def confirm
  end

  def update
    attempted_access_url = discard_stashed_redirect_for(:sign_in)
    discard_pending_sign_in
    start_new_session_for @magic_link.user
    redirect_to attempted_access_url || dashboard_url
  end

  private
    def rate_limit_response
      render Peak::Error("Too many sign-in attempts. Try again later."), status: :too_many_requests
    end

    def set_magic_link
      @magic_link = User::MagicLink.find_by_token(params[:token]) or
        redirect_to_invalid_magic_link
    end

    def set_pending_magic_link
      @magic_link = pending_sign_in_token && User::MagicLink.find_by_token(pending_sign_in_token)
      @confirmation_nonce = pending_sign_in_nonce
      redirect_to_invalid_magic_link unless @magic_link && @confirmation_nonce
    end

    def verify_confirmation_nonce
      redirect_to_invalid_magic_link unless confirmation_nonce_matches?
    end

    def stash_pending_sign_in(token)
      session[:pending_sign_in] = [token, SecureRandom.hex]
    end

    def pending_sign_in
      session[:pending_sign_in]
    end

    def pending_sign_in_token
      pending_sign_in&.first
    end

    def pending_sign_in_nonce
      pending_sign_in&.second
    end

    def confirmation_nonce_matches?
      pending_sign_in_nonce.present? &&
        ActiveSupport::SecurityUtils.secure_compare(
          pending_sign_in_nonce,
          params[:confirmation_nonce].to_s
        )
    end

    def discard_pending_sign_in
      session.delete(:pending_sign_in)
    end

    def redirect_to_invalid_magic_link
      discard_pending_sign_in
      redirect_to new_sign_in_url,
        alert: "That sign-in link is invalid or has expired. Try again."
    end
end
