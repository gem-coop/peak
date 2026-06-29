class User::SignUpsController < Public::BaseController
  rate_limit only: :create, to: 20, within: 1.minute, by: -> { "burst" }, with: :burst_rate_limit_response
  rate_limit only: :create, to: 5,  within: 1.day,    by: :email_address_rate_limiting_key, with: :short_rate_limit_response
  throttle_responses on: :create

  def new
    @sign_up = User::SignUp.new(**params.permit(:name, :email_address).to_h.symbolize_keys)
  end

  def create
    @sign_up = User::SignUp.new(**sign_up_params.to_h.symbolize_keys)

    unless @sign_up.save
      self.class.rate_limiting(by: email_address_rate_limiting_key).decrement
      render :new, status: :unprocessable_entity
    end
  end

  private
    def burst_rate_limit_response
      render Peak::Error("Sign up is temporarily disabled. Try again later."), status: :too_many_requests
    end

    def short_rate_limit_response
      render Peak::Error("Woah buddy! That's enough namespaces for a day. Try again tomorrow."), status: :too_many_requests
    end

    def email_address_rate_limiting_key
      sign_up_params[:email_address].to_s.downcase
    end

    helper_method def sign_up_params
      params.expect(user_sign_up: %i[name email_address namespace_name])
    end
end
