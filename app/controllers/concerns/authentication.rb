module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
  end

  class_methods do
    def require_authentication(**options)
      before_action :require_authentication, **options
    end
  end

  private
    def require_authentication
      resume_session || redirect_to_sign_in
    end
    def redirect_to_sign_in = redirect_to(sign_in_url(redirect_url: request.url))

    def resume_session
      if id = session[:user_session_id]
        Current.session ||= User::Session.find_by(id:)
      end
    end

    def start_new_session_for(user)
      reset_session
      Current.session = user.sessions.create!(ip_address: request.remote_ip, user_agent: request.user_agent)
      session[:user_session_id] = Current.session.id
    end

    def terminate_session
      reset_session
      Current.session&.destroy
    end
end
