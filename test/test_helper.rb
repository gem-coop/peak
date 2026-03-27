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
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    get user_session_url(user.magic_link.signed_id)
  end
end
