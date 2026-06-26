require "test_helper"

class Peak::CompactIndexTest < ActiveSupport::TestCase
  test "returns safe values unchanged" do
    ["oaken", ">= 4.0", "MIT&Apache", "checksum:abc", "0.1.0-arm-linux", 123].each do |value|
      assert_equal value, Peak::CompactIndex.safe(value)
    end

    assert_nil Peak::CompactIndex.safe(nil)
  end

  test "raises on line terminators and null bytes" do
    ["safe\nforged", "a\rb", "a\x00b", "trailing\n"].each do |value|
      assert_raises(Peak::CompactIndex::UnsafeValue, value.inspect) do
        Peak::CompactIndex.safe(value)
      end
    end
  end
end
