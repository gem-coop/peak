Rails.application.configure do
  host =
    case
    when Rails.env.development? then "peak.test"
    when Rails.env.test? then "example.com"
    else
      "beta.gem.coop"
    end

  Peak.define_singleton_method(:host) { host }

  Rails.application.routes.default_url_options = { host: }
  config.action_controller.default_url_options = { host: }
  config.action_mailer.default_url_options = { host: }
end
