class SlackNotifyNamespaceRequestedJob < ApplicationJob
  queue_as :default

  def perform(namespace)
    Slack.notify message_for(namespace)
  end

  private def message_for(namespace)
    "Namespace #{namespace.name} requested\n#{Route.avo.resources_namespace_url(namespace)}".chomp
  end
end
