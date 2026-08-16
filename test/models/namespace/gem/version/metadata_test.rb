require "test_helper"

class Namespace::Gem::Version::MetadataTest < ActiveSupport::TestCase
  test "basic parsing" do
    metadatas = gems.oaken.versions
    assert metadatas.all?(&:checksum?)
    assert_empty metadata.filter_map(&:rubygems)

    rubies = metadatas.pluck :ruby
    assert_includes rubies, ">= 3.2"
    assert_includes rubies, ">= 3.0.0"
  end

  test "line" do
    assert_line "|ruby:>= 4.0",     ruby: [">= 4.0"]
    assert_line "|ruby:>= 4.0&< 5", ruby: [">= 4.0", "< 5"]

    assert_line "|rubygems:>= 4.0",     rubygems: [">= 4.0"]
    assert_line "|rubygems:>= 4.0&< 5", rubygems: [">= 4.0", "< 5"]

    assert_line "|licenses:MIT",     licenses: ["MIT"]
    assert_line "|licenses:MIT&GPL", licenses: ["MIT", "GPL"]

    assert_line "|executables:peak",       executables: ["peak"]
    assert_line "|executables:peak&rails", executables: ["peak", "rails"]
  end

  private
    def assert_line(exp, **)
      assert_match exp, Namespace::Gem::Version.new(**, published_at: nil).metadata.line
    end
end
