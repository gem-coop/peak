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
end
