require "test_helper"

class Namespace::MirrorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").to_return(
      body: file_fixture("rake.json").open, headers: {"content-type": "application/json"})
  end

  test "import versions" do
    stub_request(:get, "https://rubygems.org/versions").to_return(body: file_fixture("versions").read.lines[0...-4].join)
    stub_request(:get, "https://rubygems.org/info/rake").to_return(body: file_fixture("info/rake").read.lines[0...-3].join)
    perform_import

    versions_map = {
      "actionview" => ["7.0.10", "7.0.9", "7.1.6", "7.2.3", "8.0.4", "8.1.0", "8.1.0.rc1", "8.1.1", "8.1.2"],
      "activerecord" => ["8.1.1"],
      "activesupport" => ["8.1.1"],
      "oaken" => ["0.9.1", "1.0.0"],
      "rake" => ["0.4.10", "0.4.11", "0.4.12", "0.4.13", "0.4.14", "0.4.15", "0.4.8", "0.4.9", "0.5.0", "0.5.3", "0.5.4", "0.6.0", "0.6.2", "0.7.0", "0.7.1", "0.7.2", "0.7.3", "0.8.0", "0.8.1", "0.8.2", "0.8.3", "0.8.4", "0.8.5", "0.8.6", "0.8.7", "0.9.0", "0.9.0.beta.0", "0.9.0.beta.1", "0.9.0.beta.2", "0.9.0.beta.4", "0.9.0.beta.5", "0.9.1", "0.9.2", "0.9.2.2", "0.9.3", "0.9.3.beta.1", "0.9.3.beta.2", "0.9.3.beta.3", "0.9.3.beta.4", "0.9.4", "0.9.5", "0.9.6", "10.0.0", "10.0.0.beta.1", "10.0.0.beta.2", "10.0.1", "10.0.2", "10.0.3", "10.0.4", "10.1.0", "10.1.0.beta.1", "10.1.0.beta.2", "10.1.0.beta.3", "10.1.1", "10.2.0", "10.2.1", "10.2.2", "10.3.0", "10.3.1", "10.3.2", "10.4.0", "10.4.1", "10.4.2", "10.5.0", "11.0.1", "11.1.0", "11.1.1", "11.1.2", "11.2.0", "11.2.2", "11.3.0", "12.0.0", "12.0.0.beta1", "12.1.0", "12.2.0", "12.2.1", "12.3.0", "12.3.1", "12.3.2", "12.3.3", "13.0.0", "13.0.0.pre.1", "13.0.1", "13.0.2", "13.0.3", "13.0.4", "13.0.5", "13.0.6", "13.1.0", "13.2.0"]
    }

    assert_equal 103, public_versions.values.map(&:count).sum
    assert_equal versions_map, public_versions

    stub_request(:get, "https://rubygems.org/versions").to_return(body: file_fixture("versions").read)
    stub_request(:get, "https://rubygems.org/info/rake").to_return(body: file_fixture("info/rake").read)
    perform_import

    # get the whole file if we don't have a byte offset
    assert_equal file_fixture("versions").read, mirrors.public.upstream.versions
    assert_equal file_fixture("info/rake").read, mirrors.public.upstream.info("rake")

    assert_equal versions_map["rake"], public_versions["rake"]
    assert_equal 103, public_versions.values.map(&:count).sum
    assert_equal versions_map, public_versions
  end

# test "import versions after compaction"
# test "import versions when a yank was hidden by compaction"

private

  def perform_import
    Rails.cache.clear
    Namespace::Mirror::Upstream.memory_store.clear
    mirrors.public.import
    perform_enqueued_jobs
  end

  def public_versions
    namespaces.public.versions.pluck(:name, :ref).
      sort_by { |n, _| n }.
      group_by { |n, _| n }.
      transform_values { |v| v.map { |k, v| v }.sort }
  end
end
