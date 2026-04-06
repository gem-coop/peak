class SlackNotifyNamespaceRequestedJob < ApplicationJob
  queue_as :default

  include Avo::Engine.routes.url_helpers if Peak.avo?

  def perform(namespace)
    Slack.notify message_for(namespace)
  end

  def message_for(namespace)
    "Namespace #{namespace.name} requested".tap do |msg|
      msg << "\n" << resources_namespace_url(namespace) if Peak.avo?
    end
  end
end
