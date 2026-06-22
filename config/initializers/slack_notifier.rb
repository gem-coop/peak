Rails.application.config.after_initialize do
  module Slack
    mattr_accessor :webhook_url

    def self.notify(object, title)
      if webhook_url
        url = Route.avo.polymorphic_url([:resources, object])
        message = [Peak.env_tag, title, "\n", url].compact.join.chomp

        Slack::Notifier.new(webhook_url).ping(message)
      end
    end
  end

  Slack.webhook_url = ENV["SLACK_WEBHOOK_URL"]
end
