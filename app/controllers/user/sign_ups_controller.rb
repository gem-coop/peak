class User::SignUpsController < Public::BaseController
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
    def sign_up_params
      params.expect(user_sign_up: %i[name email_address namespace_name])
    end
end
