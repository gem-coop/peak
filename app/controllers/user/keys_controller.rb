class User::KeysController < ApplicationController
  def show
    if user = User.find_by_token_for(:push_key_install, params[:id])
      render plain: user.push_key
    else
      render plain: "Token doesn't exist or has expired", status: :unauthorized
    end
  end
end
