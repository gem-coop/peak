class User::SignUpsController < Public::BaseController
  throttle_responses on: :create

  def new
    @sign_up = User::SignUp.new
  end

  def create
    @sign_up = User::SignUp.new(**sign_up_params.to_h.symbolize_keys)
    render :new, status: :unprocessable_entity unless @sign_up.save
  end

  private
    def sign_up_params
      params.expect(user_sign_up: %i[name email_address namespace_name])
    end
end
