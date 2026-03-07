Rails.application.config.after_initialize do
  module Slack
    mattr_accessor :webhook_url

    def self.notify(message)
      notifier&.ping message
    end

    def self.notifier
      return unless webhook_url

      @notifier ||= Slack::Notifier.new webhook_url
    end
  end

  Slack.webhook_url = ENV["SLACK_WEBHOOK_URL"]
end
