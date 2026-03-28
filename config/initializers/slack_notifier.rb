Rails.application.config.after_initialize do
  module Slack
    mattr_accessor :webhook_url

    def self.notify(message)
      notifier&.ping message
    end

    def self.notify_namespace(ns)
      notify NoticeWriter.new.namespace(ns)
    end

    def self.notifier
      return unless webhook_url

      @notifier ||= Slack::Notifier.new webhook_url
    end

    class NoticeWriter
      include Rails.application.routes.url_helpers

      def namespace(ns)
        "Namespace #{ns.name} requested\n#{avo.resources_namespace_url(ns)}"
      end
    end
  end

  Slack.webhook_url = ENV["SLACK_WEBHOOK_URL"]
end
