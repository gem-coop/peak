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

  def peak_upload_from(contents)
    Current.upload_from StringIO.new contents
  end

  def gem_package_from(**values)
    Dir.chdir Dir.mktmpdir do
      File.write "safe.rb", "Safe = Module.new\n"

      values[:executables]&.each do |name|
        Pathname.pwd.join("bin").tap(&:mkpath).join(name).write "# lol"
      end

      spec = Gem::Specification.new
      values.with_defaults(name: "safe", version: "1.0.0", summary: "summary", author: "author", files: ["safe.rb"]).each do |key, value|
        spec.public_send "#{key}=", value
      end

      Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
        File.binread Gem::Package.build(spec, true, false) # Build `.gem` with skip-validation so unsafe links survive into the package.
      end
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_as(user)
    get sign_in_url(user.magic_link.token)
  end

  def dom(selector)
    response.parsed_body.css(selector)
  end

  def peak_admin_authorization
    { "HTTP_AUTHORIZATION" => ADMIN_AUTHORIZATION }
  end

  ADMIN_AUTHORIZATION = ActionController::HttpAuthentication::Basic.encode_credentials(Peak.admin.username, Peak.admin.password)

  def assert_ok
    assert_response :success
    assert_dom "peak-ok"
  end

  def assert_error(status)
    assert_response status
    assert_dom "peak-error"
  end
end
