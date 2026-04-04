Rails.application.config.after_initialize do
  module Slack
    mattr_accessor :webhook_url

    def self.notify(message)
      webhook_url && Slack::Notifier.new(webhook_url).ping(message)
    end
  end

  Slack.webhook_url = ENV["SLACK_WEBHOOK_URL"]
end
