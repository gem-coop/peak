class User::PushKeysController < ApplicationController
  rate_limit to: 1, within: 30.seconds, with: :rate_limit_response, only: :create
  rate_limit to: 1, within: 30.seconds, by: :email_address_rate_limiting_key, with: :rate_limit_response, only: :create

  def new
  end

  def create
    if user = User.find_by(email_address: params[:email_address])
      user.create_push_key.sign_in_mailer.deliver_later
    end

    render Peak::Status("Email sent! Check your spam folder too, just in case.")
  end

  private
    def email_address_rate_limiting_key
      User.normalize_value_for :email_address, params[:email_address].to_s
    end

    def rate_limit_response
      render Peak::Error("You can only request a new push key once every 30 seconds. Try again later."), status: :too_many_requests
    end
end
