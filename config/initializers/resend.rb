Rails.application.configure do
  Resend.api_key = ENV["RESEND_API_KEY"]
end
