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

  def stub_rubygems(scenario)
    dir = Rails.root.join("test/fixtures/files").join(scenario)
    stub_request(:get, "https://rubygems.org/versions").
      to_return(body: dir.join("versions").open)
    dir.glob("info/*").each do |file|
      stub_request(:get, "https://rubygems.org/info/#{file.basename}").
        to_return(body: file.open)
    end
    dir.glob("api/v1/versions/*").each do |file|
      stub_request(:get, "https://rubygems.org/api/v1/versions/#{file.basename}").
        to_return(body: file.open, headers: {"content-type": "application/json"})
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    get sign_in_url(user.magic_link.signed_id)
  end
end
