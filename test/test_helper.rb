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

  def refute_increments(*positionals, &)
    assert_no_difference(positionals.map { _1.method(:count) }, &)
  end
end

class ActionDispatch::IntegrationTest
  attr_reader :user, :namespace

  def sign_in(user, to: namespaces.gemcoop)
    to.accesses.exists?(user:) or raise ArgumentError, "user doesn't have access to namespace #{to.inspect}"

    @user, @namespace = user, to
    host! "#{host}/#{to.name}"
  end
end
