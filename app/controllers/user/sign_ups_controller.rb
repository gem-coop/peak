class User::SignUpsController < Public::BaseController
  rate_limit to: 1, within: 30.seconds, with: :rate_limit_response, only: :create

  def new
    @sign_up = User::SignUp.new
  end

  def create
    @sign_up = User::SignUp.new(**sign_up_params.to_h.symbolize_keys)

    if @sign_up.save
      @sign_up.user.mailer.welcome.deliver_later
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def rate_limit_response
      render Peak::Error("Too many sign-up attempts. Try again later."), status: :too_many_requests
    end

    def sign_up_params
      params.expect(user_sign_up: %i[name email_address namespace_name])
    end
end
