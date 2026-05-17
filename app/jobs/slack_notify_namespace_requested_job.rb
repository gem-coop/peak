class SlackNotifyNamespaceRequestedJob < ApplicationJob
  queue_as :default

  def perform(namespace)
    Slack.notify message_for(namespace)
  end

  private def message_for(namespace)
    msg = ""
    msg << "[#{Peak.env.capitalize}] " unless Peak.env.production?
    msg << "Namespace #{namespace.name} requested\n"
    msg << "#{Route.avo.resources_namespace_url(namespace)}"
    msg.chomp
  end
end
