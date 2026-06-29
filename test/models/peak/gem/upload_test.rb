require "test_helper"

class Peak::Gem::UploadTest < ActiveSupport::TestCase
  test "links drops unsafe URI schemes and keeps web links" do
    upload = peak_upload_from gem_package_from(homepage: "javascript:alert(1)", metadata: {
      "source_code_uri" => "https://example.com/src",
      "bug_tracker_uri" => "javascript:alert(2)",
      "changelog_uri"   => "data:text/html,evil"
    })

    assert_equal({ source_code: "https://example.com/src" }, upload.links)
  end

  test "validation" do
    assert peak_upload_from(gem_package_from(required_ruby_version: [">=\n 4.0\r"])).validate
    assert peak_upload_from(gem_package_from(required_rubygems_version: [">=\r4.0\n"])).validate

    assert_invalid_upload gem_package_from(licenses: ["MIT\nFORGED"])
    assert_invalid_upload gem_package_from(executables: ["peak\nforged"])
  end

  test "ref format" do
    refute valid_ref?("1.0\n9")
    refute valid_ref?("1.0 0")
    refute valid_ref?("v1")
    refute valid_ref?("")
    refute valid_ref?("1.0.0; rm -rf")

    assert valid_ref?("1.0.0")
    assert valid_ref?("0.9.1")
    assert valid_ref?("1.0.0-arm-linux")
    assert valid_ref?("8.1.0.pre.1")
  end

  private
    delegate :valid_ref?, to: Peak::Gem::Upload

    def assert_invalid_upload(contents)
      assert_raise(Peak::Gem::Upload::InvalidError) { peak_upload_from(contents).validate }
    end
end
