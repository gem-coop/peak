Rails.application.configure do
  if Rails.env.production?
    MissionControl::Jobs.http_basic_auth_user = "gemcoop"
    MissionControl::Jobs.http_basic_auth_password = ENV["JOBS_PASSWORD"]
  end
end
