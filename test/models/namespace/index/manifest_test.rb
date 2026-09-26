require "test_helper"

class Namespace::Index::ManifestTest < ActiveSupport::TestCase
  test "index compaction" do
    manifest = namespaces.rubygems.stable_index.manifest
    assert_changes(-> { manifest.compacted_at }) { manifest.compact }

    lines = manifest.contents.lines
    assert_equal lines.size, lines.uniq.size

    lines = lines.drop(2) # Drop metadata lines
    assert_equal lines, lines.sort_by { _1.split(" ").first }

    assert_includes lines, "oaken 0.9.1,1.0.0 33837e788e120ccc642d3c4dc7e0f532\n"
    assert_includes lines, "activesupport 8.1.1 14576e848f997e40e8b92864a3e84cfb\n"
    assert_includes lines, "actionview 7.0.9,7.0.10,7.1.6,7.2.3,8.0.4,8.1.0,8.1.0.rc1,8.1.1,8.1.2 2bbe194954a8e9129fb50e76a80b7579\n"
    assert_includes lines, manifest.versions.latest_for(:actionview).envelope
  end

  test "cooldown compaction" do
    cooldown = namespaces.rubygems.stable_index.cooldowns.create
    travel 2.days + 1.second

    cooldown.index.versions.for(:actionview).where("namespace_gem_versions.ref LIKE '8%'").update_all published_at: 1.second.ago
    cooldown.index.versions.latest_for(:activesupport).update! published_at: 1.second.ago
    cooldown.index.versions.latest_for(:oaken).update! published_at: 1.second.ago

    manifest = cooldown.manifest
    assert_changes(-> { manifest.compacted_at }) { manifest.compact }

    lines = manifest.contents.lines
    assert_equal lines.size, lines.uniq.size

    lines = lines.drop(2) # Drop metadata lines
    assert_equal lines, lines.sort_by { _1.split(" ").first }

    assert_includes lines, "oaken 0.9.1 cbc0bdc1633e8ee470c322abc91340b0\n"
    refute_includes lines, "activesupport 8.1.1 14576e848f997e40e8b92864a3e84cfb\n"
    assert_includes lines, "actionview 7.0.9,7.0.10,7.1.6,7.2.3 fc355f85935a75c158b042ed679f73cd\n"
    assert_includes lines, cooldown.versions.latest_for(:actionview).envelope
  end

  test "concurrent appends keep every entry" do
    manifest = namespaces.blank.stable_index.manifest
    oaken = gems.oaken.versions.first
    peak  = gems.peak.versions.first

    # Two requests both read the manifest, then both append — the classic lost-update race.
    first = Namespace::Index::Manifest.find(manifest.id)
    stale = Namespace::Index::Manifest.find(manifest.id) # loaded before `first` writes
    first.append [oaken]
    stale.append [peak]

    manifest.reload
    assert_includes manifest.contents, oaken.envelope(ref_stamp: oaken.ref)
    assert_includes manifest.contents, peak.envelope(ref_stamp: peak.ref)
  end

  test "compact queries are fixed regardless of version count" do
    manifest = namespaces.rubygems.stable_index.manifest
    queries = count_queries { manifest.compact }
    assert_equal 5, queries

    cooldown = namespaces.rubygems.stable_index.cooldowns.create.manifest
    queries = count_queries { manifest.compact }
    assert_equal 5, queries
  end

  private
    def count_queries(&block)
      count = 0
      callback = ->(*args) { count += 1 unless args.last[:name] == "SCHEMA" }
      ActiveSupport::Notifications.subscribed(callback, "sql.active_record", &block)
      count
    end
end
