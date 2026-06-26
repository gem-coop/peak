require "test_helper"

class Namespace::GemTest < ActiveSupport::TestCase
  # Name rules mirror RubyGems' validate_name.
  test "rejects names RubyGems itself rejects" do
    index = gems.oaken.index

    bad = [
      "safe\nforged 9.9.9 deadbeef", "safe\rforged", "safe\x00x", # control bytes / newline injection
      "has space", "name@evil", "a/b", "a:b",                     # characters outside [a-zA-Z0-9._-]
      "_leading", "-leading", ".leading",                        # may not begin with . - _
      "1.2.3", "9"                                               # must include at least one letter
    ]

    bad.each do |name|
      gem = index.gems.build(name:)
      assert gem.invalid?, "expected #{name.inspect} to be invalid"
      assert gem.errors.of_kind?(:name, :invalid), "expected a name format error for #{name.inspect}"
    end
  end

  test "accepts every name RubyGems accepts" do
    index = gems.oaken.index

    %w[oaken active_job-performs rails-html-sanitizer a.b Foo_Bar.9 a 9foo].each do |name|
      gem = index.gems.build(name:)
      assert gem.valid?, "expected #{name.inspect} to be valid, got #{gem.errors.full_messages.inspect}"
    end
  end

  test "referrants" do
    version = versions.by gems.activesupport, ref: "8.1.1"
    referrant = version.referrants.sole

    assert referrant.eq?
    assert_equal "8.1.1", referrant.ref
    assert_includes gems.activesupport.referrants, referrant
  end
end
