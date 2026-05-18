Rails.application.configure do
  host =
    case
    when Rails.env.development? then "peak.test"
    when Rails.env.test? then "example.com"
    when Rails.env.production?
      case
      when Peak.env.staging? then "staging.gem.coop"
      when Peak.env.production? then "gem.coop"
      end
    end

  if host.nil?
    raise "Unknown host for Rails env #{Rails.env} and Peak env #{Peak.env}"
  end

  Avo::Engine.routes.default_url_options = { host: } if Peak.avo?
  Rails.application.routes.default_url_options = { host: }
  config.action_controller.default_url_options = { host: }
  config.action_mailer.default_url_options = { host: }
end
