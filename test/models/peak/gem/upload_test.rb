require "test_helper"

class Peak::Gem::UploadTest < ActiveSupport::TestCase
  test "links drops unsafe URI schemes and keeps web links" do
    upload = peak_upload_from gem_package_from(homepage: "javascript:alert(1)", metadata: {
      "source_code_uri" => "https://example.com/src",
      "bug_tracker_uri" => "javascript:alert(2)",
      "changelog_uri"   => "data:text/html,evil"
    })

    assert_equal({ source_code: "https://example.com/src" }, upload.spec.links)
  end

  test "validation" do
    assert peak_upload_from(gem_package_from(required_ruby_version: [">=\n 4.0\r"])).spec.validate
    assert peak_upload_from(gem_package_from(required_rubygems_version: [">=\r4.0\n"])).spec.validate

    assert peak_upload_from(gem_package_from(required_ruby_version: [">=\n 4.0\r", ">=\n 4.1"])).spec.validate
    assert peak_upload_from(gem_package_from(required_rubygems_version: [">=\r4.0\n", ">=\r4.1\n"])).spec.validate

    # RubyGems does sanitation on requirements, but not gem names. So the above tests are valid, but the below aren't:
    assert_invalid_upload gem_package_from { _1.add_dependency "ruby-ajp\n", ">= 0.2.0" }
    assert_invalid_upload gem_package_from { _1.add_dependency "rails&", ">= 0.14" }

    assert_invalid_upload gem_package_from(licenses: ["MIT\nFORGED"])
    assert_invalid_upload gem_package_from(executables: ["peak\nforged"])
  end

  test "validation with jar requirements" do
    requirements = [
      "jar org.bouncycastle:bcprov-jdk18on, 1.80",
      "jar org.bouncycastle:bcpkix-jdk18on, 1.80",
      "jar org.bouncycastle:bctls-jdk18on, 1.80",
      "jar org.bouncycastle:bcutil-jdk18on, 1.80"
    ]
    upload = peak_upload_from gem_package_from(platform: "java", requirements:)

    assert upload.spec.validate
    assert_equal requirements, upload.spec.spec.requirements
  end

  test "ref format" do
    refute valid_ref?("1.0\n9")
    refute valid_ref?("1.0 0")
    refute valid_ref?("1.0.0-x86_64-linux")
    refute valid_ref?("v1")
    refute valid_ref?("")
    refute valid_ref?("1.0.0; rm -rf")

    assert valid_ref?("1.0.0")
    assert valid_ref?("0.9.1")
    assert valid_ref?("8.1.0.pre.1")
  end

  private
    delegate :valid_ref?, to: Peak::Gem::Gemspec

    def assert_invalid_upload(contents)
      assert_raise(Peak::Gem::Gemspec::InvalidError) { peak_upload_from(contents).spec.validate }
    end
end
