require "test_helper"

class Namespace::Index::ManifestTest < ActiveSupport::TestCase
  test "compact" do
    manifest = namespaces.public.default_index.manifest
    assert_changes(-> { manifest.compacted_at }) { manifest.compact }

    lines = manifest.contents.lines
    assert_contents_shape lines

    assert_includes lines, "oaken 0.9.1,1.0.0 33837e788e120ccc642d3c4dc7e0f532\n"
    assert_includes lines, "activesupport 8.1.1 14576e848f997e40e8b92864a3e84cfb\n"
    assert_includes lines, "actionview 7.0.9,7.0.10,7.1.6,7.2.3,8.0.4,8.1.0,8.1.0.rc1,8.1.1,8.1.2 2bbe194954a8e9129fb50e76a80b7579\n"
    assert_includes lines, manifest.versions.latest_for(:actionview).envelope
  end

  test "compact when previously compacted" do
    manifest = namespaces.public.default_index.manifest.tap(&:compact)

    manifest.update! contents: manifest.contents << "actionview 7.0.0 abcdef\noaken 0.5.0 abcdef\n"
    manifest.compact

    lines = manifest.contents.lines
    assert_contents_shape lines

    assert_includes lines, "activesupport 8.1.1 14576e848f997e40e8b92864a3e84cfb\n"
    assert_includes lines, "actionview 7.0.0,7.0.1,7.0.9,7.0.10,7.1.6,7.2.3,8.0.4,8.1.0,8.1.0.rc1,8.1.1,8.1.2 2bbe194954a8e9129fb50e76a80b7579\n"
    assert_includes lines, "oaken 0.5.0,0.9.1,1.0.0 33837e788e120ccc642d3c4dc7e0f532\n"
    assert_includes lines, manifest.versions.latest_for(:actionview).envelope
  end

  test "compact cooldown" do
    cooldown = namespaces.public.default_index.cooldowns.create
    travel 2.days + 1.second

    cooldown.index.versions.for(:actionview).where("namespace_gem_versions.ref LIKE '8%'").update_all published_at: 1.second.ago
    cooldown.index.versions.latest_for(:activesupport).update! published_at: 1.second.ago
    cooldown.index.versions.latest_for(:oaken).update! published_at: 1.second.ago

    manifest = cooldown.manifest
    assert_changes(-> { manifest.compacted_at }) { manifest.compact }

    lines = manifest.contents.lines
    assert_contents_shape lines

    assert_includes lines, "oaken 0.9.1 cbc0bdc1633e8ee470c322abc91340b0\n"
    refute_includes lines, "activesupport 8.1.1 14576e848f997e40e8b92864a3e84cfb\n"
    assert_includes lines, "actionview 7.0.9,7.0.10,7.1.6,7.2.3 fc355f85935a75c158b042ed679f73cd\n"
    assert_includes lines, cooldown.versions.latest_for(:actionview).envelope
  end

  private
    def assert_contents_shape(lines)
      assert_equal lines.size, lines.uniq.size

      lines = lines.slice(2..) # Drop metadata lines
      assert_equal lines, lines.sort_by { _1.split(" ", 2).first }
    end
end
