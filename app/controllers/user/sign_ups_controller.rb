class User::SignUpsController < Public::BaseController
  throttle_responses on: :create
  rate_limit only: :create, to: 5, within: 1.day, by: :email_address_rate_limiting_key, with: :rate_limit_response

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
    def rate_limit_response
      render Peak::Error("Woah buddy! That's enough namespaces for a day. Try again tomorrow."), status: :too_many_requests
    end

    def email_address_rate_limiting_key
      sign_up_params[:email_address].to_s.downcase
    end

    helper_method def sign_up_params
      params.expect(user_sign_up: %i[name email_address namespace_name])
    end
end
