require "test_helper"

class SlackNotifyNamespaceRequestedJobTest < ActiveJob::TestCase
  test "it notifies slack" do
    Slack.with webhook_url: "https://slack.test/webhook" do
      msg = "Namespace @slacktest requested\nhttp://www.example.com/avo/resources/namespaces/@slacktest"
      webhook = stub_request(:post, "https://slack.test/webhook").
        with(body: {"payload" => JSON.dump({"text": msg})})

      namespace = Namespace.build(name: "@slacktest")
      SlackNotifyNamespaceRequestedJob.perform_now(namespace)
      assert_requested(webhook)
    end
  end
end
