require "test_helper"

class Peak::Gem::UploadTest < ActiveSupport::TestCase
  test "validation" do
    assert uploaded_spec(required_ruby_version: [">=\n 4.0\r"]).validate
    assert uploaded_spec(required_rubygems_version: [">=\r4.0\n"]).validate

    assert uploaded_spec(required_ruby_version: [">=\n 4.0\r", ">=\n 4.1"]).validate
    assert uploaded_spec(required_rubygems_version: [">=\r4.0\n", ">=\r4.1\n"]).validate

    # RubyGems does sanitation on requirements, but not gem names. So the above tests are valid, but the below aren't:
    assert_invalid_spec(uploaded_spec { _1.add_dependency "ruby-ajp\n", ">= 0.2.0" })
    assert_invalid_spec(uploaded_spec { _1.add_dependency "rails&", ">= 0.14" })

    assert_invalid_spec uploaded_spec(licenses: ["MIT\nFORGED"])
    assert_invalid_spec uploaded_spec(executables: ["peak\nforged"])
  end

  test "validation with jar requirements" do
    requirements = [
      "jar org.bouncycastle:bcprov-jdk18on, 1.80",
      "jar org.bouncycastle:bcpkix-jdk18on, 1.80",
      "jar org.bouncycastle:bctls-jdk18on, 1.80",
      "jar org.bouncycastle:bcutil-jdk18on, 1.80"
    ]
    spec = uploaded_spec(platform: "java", requirements:)

    assert spec.validate
    assert_equal requirements, spec.spec.requirements
  end

  private
    def uploaded_spec(...)
      peak_upload_from(gem_package_from(...)).spec
    end

    def assert_invalid_spec(spec)
      assert_raise(Peak::Gem::Gemspec::InvalidError) { spec.validate }
    end
end
