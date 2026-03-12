module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :resume_session
    helper_method :authenticated?
  end

  class_methods do
    def require_authentication(**options)
      before_action :require_authentication, **options
    end
  end

  private
    def authenticated?
      Current.session.present?
    end

    def require_authentication
      resume_session || request_authentication
    end

    def resume_session
      Current.session ||= find_session_by_cookie
    end

    def find_session_by_cookie
      User::Session.find_by(id: session[:user_session_id]) if session[:user_session_id]
    end

    def request_authentication
      redirect_to sign_in_url(redirect_url: request.url)
    end

    def start_new_session_for(user)
      user.sessions.create!(user_agent: request.user_agent, ip_address: request.remote_ip).tap do |session_record|
        Current.session = session_record
        session[:user_session_id] = session_record.id
      end
    end

    def terminate_session
      Current.session.destroy
      session.delete(:user_session_id)
    end
end
