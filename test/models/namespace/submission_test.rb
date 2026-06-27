require "test_helper"

class Namespace::SubmissionTest < ActiveSupport::TestCase
  include ActionMailer::TestCase::Behavior

  test "notifies slack" do
    submission = submissions.basic

    assert_slack_request title: "Namespace @basic requested", avo_path: "namespace/submissions/#{submission.id}" do
      submission.slack_notify
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

  private
    def assert_name_clash(name)
      submissions.create(name:).errors[:name].any?
    end
end
