Rails.application.configure do
  host =
    case Rails.env
    when "development" then "peak.test"
    when "test" then "example.com"
    when "production"
      case ENV.fetch("PEAK_ENV", "production")
      when "staging" then "staging.gem.coop"
      when "production" then "gem.coop"
      end
    end

  if host.nil?
    raise "Unknown host for RAILS_ENV #{ENV["RAILS_ENV"].inspect} and PEAK_ENV #{ENV["PEAK_ENV"].inspect}"
  end

  Avo::Engine.routes.default_url_options = { host: } if Peak.avo?
  Rails.application.routes.default_url_options = { host: }
  config.action_controller.default_url_options = { host: }
  config.action_mailer.default_url_options = { host: }
end
