# frozen_string_literal: true

class SlackNotifyNamespaceRequestedJob < ApplicationJob
  queue_as :default

  def perform(namespace)
    Slack.notify message_for(namespace)
  end

  private def message_for(namespace)
    msg = String.new
    msg << "[#{Peak.env.upcase}] " unless Peak.env.production?
    msg << "Namespace #{namespace.name} requested\n"
    msg << Route.avo.resources_namespace_url(namespace).to_s
    msg.chomp
  end
end
