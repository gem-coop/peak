ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

class ActiveSupport::TestCase
  parallelize workers: :number_of_processors

  include Oaken.test_setup

  def assert_increments(*positionals, by: 1, **explicits, &)
    diffs = explicits.merge(positionals.index_with(by)).transform_keys { _1.method(:count) }
    assert_difference(diffs, &)
  end

  def assert_decrements(*positionals, by: 1, **explicits, &)
    diffs = explicits.merge(positionals.index_with(by)).to_h { [_1.method(:count), -_2] }
    assert_difference(diffs, &)
  end

  def refute_increments(*positionals, &)
    assert_no_difference(positionals.map { _1.method(:count) }, &)
  end

  def assert_slack_request(title:, avo_path:)
    Slack.with webhook_url: "https://slack.test/webhook" do
      text = +"[TEST] #{title}"
      text << "\nhttp://example.com/avo/resources/#{avo_path}" if Peak.avo?
      webhook = stub_request(:post, Slack.webhook_url).with(body: {"payload" => JSON.dump({text:})})

      yield.tap do
        assert_requested webhook
      end
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    get sign_in_url(user.magic_link.signed_id)
  end
end
