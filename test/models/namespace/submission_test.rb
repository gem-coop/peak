require "test_helper"

class Namespace::SubmissionTest < ActiveSupport::TestCase
  include ActionMailer::TestCase::Behavior

  test "notifies slack" do
    submission = submissions.basic

    assert_slack_request title: "Namespace @basic requested", avo_path: "namespace/submissions/#{submission.id}" do
      submission.slack_notify
    end
  end

  test "does not notify slack until owner verifies email address" do
    submission = Namespace::Submission.create!(name: "@unverified", owner: users.unverified_plain)

    Slack.with webhook_url: "https://slack.test/webhook" do
      webhook = stub_request(:post, Slack.webhook_url)

      perform_enqueued_jobs
      assert_not_requested webhook

      users.unverified_plain.email_verification.verify
      perform_enqueued_jobs
      assert_requested webhook
    end
  end

  test "notifies slack immediately for verified owners" do
    submission = Namespace::Submission.create!(name: "@verified", owner: users.plain)

    assert_slack_request title: "Namespace @verified requested",
      avo_path: "namespace/submissions/#{submission.id}" do
      perform_enqueued_jobs
    end
  end

  test "name format" do
    assert_name_clash "@basic"

    assert submissions.build(name: "basic").valid?
    submissions.basic.rejected!

    refute submissions.build(name: "basic").valid?
    refute submissions.build(name: "@Basic").valid?
    # assert submissions.build(name: "@ba-sic").invalid? # TODO: get this working

    assert submissions.build(name: "@org-rb").valid?
    assert submissions.build(name: "@org3").valid?

    third = submissions.build(name: "org3")
    assert_equal "@org3", third.name
    assert third.valid?
  end

  test "resolve" do
    freeze_time

    submissions.basic.resolve! :approved

    submissions.basic.tap do |submission|
      assert submission.approved?
      assert_equal Time.current, submission.resolved_at
    end
  end

  test "process_approved" do
    assert_increments Namespace, Namespace::Access do
      assert_emails(1) { submissions.basic.process_approved }
    end

    Namespace::Access.last.tap do |access|
      assert access.owner?
      assert_equal submissions.basic.owner, access.user
      assert_equal submissions.basic.name, access.namespace.name
    end

    assert_raises Namespace::Submission::NamespaceAlreadyExistsError do
      submissions.basic.process_approved
    end
  end

  test "approval requires a verified owner" do
    submission = Namespace::Submission.create!(name: "@unverified", owner: users.unverified_plain)

    assert_raises Namespace::Submission::OwnerEmailUnverifiedError do
      submission.resolve! :approved
    end
    assert submission.reload.pending?

    refute_increments Namespace, Namespace::Access do
      assert_raises Namespace::Submission::OwnerEmailUnverifiedError do
        submission.process_approved
      end
    end
  end

  private
    def assert_name_clash(name)
      submissions.create(name:).errors[:name].any?
    end
end
