class Test::SignInController < ApplicationController
  def create
    start_new_session_for User.find(params[:user_id])
  end
end
