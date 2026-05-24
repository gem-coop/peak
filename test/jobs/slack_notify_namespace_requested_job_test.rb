# frozen_string_literal: true

require "test_helper"

class SlackNotifyNamespaceRequestedJobTest < ActiveJob::TestCase
  test "it notifies slack" do
    Slack.with webhook_url: "https://slack.test/webhook" do
      text = +"[TEST] Namespace @slacktest requested"
      text << "\nhttp://example.com/avo/resources/namespaces/@slacktest" if Peak.avo?
      webhook = stub_request(:post, Slack.webhook_url).with(body: {"payload" => JSON.dump({text:})})

      namespace = Namespace.build(name: "@slacktest")
      SlackNotifyNamespaceRequestedJob.perform_now(namespace)
      assert_requested(webhook)
    end
  end
end
