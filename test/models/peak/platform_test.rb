require "test_helper"

class Peak::PlatformTest < ActiveSupport::TestCase
  test "parsing" do
    assert_platform "",          "ruby",   ""
    assert_platform "universal", "darwin", ""
    assert_platform "universal", "darwin", "22"
    assert_platform "arm64",     "darwin", ""
    assert_platform "arm",       "linux",  ""
    assert_platform "arm",       "linux",  "gnueabihf"
    assert_platform "arm64",     "linux",  ""
    assert_platform "aarch64",   "linux",  ""
    assert_platform "aarch64",   "linux",  "musl"
  end

  private
    def assert_platform(arch, name, specifier, **)
      assert Peak::Platform.exists?(arch:, name:, specifier:, **)
    end
end

# == Schema Information
#
# Table name: peak_platforms
#
#  id                :bigint           not null, primary key
#  arch              :string           not null
#  key               :string
#  name              :string           not null
#  precompile_target :boolean          default(FALSE), not null
#  specifier         :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#
# Indexes
#
#  index_peak_platforms_on_arch_and_name_and_precompile_target  (arch,name,precompile_target)
#  peak_platforms_uniqueness                                    (key) UNIQUE
#
