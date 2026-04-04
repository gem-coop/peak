require "test_helper"

class SlackNotifyNamespaceRequestedJobTest < ActiveJob::TestCase
  test "it notifies slack" do
    Slack.webhook_url = "https://slack.test/webhook"

    msg = "Namespace @slacktest requested\nhttp://www.example.com/avo/resources/namespaces/@slacktest"
    webhook = stub_request(:post, "https://slack.test/webhook").
      with(body: {"payload" => JSON.dump({"text": msg})})

    ns = Namespace.build(name: "@slacktest")
    SlackNotifyNamespaceRequestedJob.new.perform(ns)
    assert_requested(webhook)
  ensure
    Slack.webhook_url = nil
  end
end
