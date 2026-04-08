require "test_helper"

class Namespace::MirrorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "import versions" do
    assert_equal [], mirror_versions("rake")

    rake_versions = ["0.4.10", "0.4.11", "0.4.12", "0.4.13", "0.4.14", "0.4.15", "0.4.8", "0.4.9", "0.5.0", "0.5.3", "0.5.4", "0.6.0", "0.6.2", "0.7.0", "0.7.1", "0.7.2", "0.7.3", "0.8.0", "0.8.1", "0.8.2", "0.8.3", "0.8.4", "0.8.5", "0.8.6", "0.8.7", "0.9.0", "0.9.0.beta.0", "0.9.0.beta.1", "0.9.0.beta.2", "0.9.0.beta.4", "0.9.0.beta.5", "0.9.1", "0.9.2", "0.9.2.2", "0.9.3", "0.9.3.beta.1", "0.9.3.beta.2", "0.9.3.beta.3", "0.9.3.beta.4", "0.9.4", "0.9.5", "0.9.6", "10.0.0", "10.0.0.beta.1", "10.0.0.beta.2", "10.0.1", "10.0.2", "10.0.3", "10.0.4", "10.1.0", "10.1.0.beta.1", "10.1.0.beta.2", "10.1.0.beta.3", "10.1.1", "10.2.0", "10.2.1", "10.2.2", "10.3.0", "10.3.1", "10.3.2", "10.4.0", "10.4.1", "10.4.2", "10.5.0", "11.0.1", "11.1.0", "11.1.1", "11.1.2", "11.2.0", "11.2.2", "11.3.0", "12.0.0", "12.0.0.beta1", "12.1.0", "12.2.0", "12.2.1", "12.3.0", "12.3.1", "12.3.2", "12.3.3"]

    stub_rubygems("1-rake-12")
    perform_import
    assert_equal rake_versions, mirror_versions("rake")
    assert_equal mirror_fixture("1-rake-12", "versions").read, mirrors.public.upstream.versions
    assert_equal mirror_fixture("1-rake-12", "info/rake").read, mirrors.public.upstream.info("rake")

    # first, add new version rows (including a yank)
    rake_versions.push(*["13.0.0", "13.0.0.pre.1", "13.0.1", "13.0.2", "13.0.3", "13.0.4", "13.0.5", "13.0.6", "13.1.0", "13.2.0", "13.2.1", "13.3.0"])

    stub_rubygems("2-rake-13")
    perform_import
    assert_equal rake_versions, mirror_versions("rake")
    assert_equal mirror_fixture("2-rake-13", "versions").read, mirrors.public.upstream.versions
    assert_equal mirror_fixture("2-rake-13", "info/rake").read, mirrors.public.upstream.info("rake")

    # next, add a completely new gem
    rake_versions.push("13.3.1")
    oaken_versions = ["0.1.0", "0.2.0", "0.5.0", "0.6.0", "0.7.0", "0.7.1", "0.8.0", "0.9.0", "0.9.1", "1.0.0"]

    stub_rubygems("3-oaken")
    perform_import
    assert_equal rake_versions, mirror_versions("rake")
    assert_equal oaken_versions, mirror_versions("oaken")
    assert_equal mirror_fixture("3-oaken", "versions").read, mirrors.public.upstream.versions
    assert_equal mirror_fixture("3-oaken", "info/rake").read, mirrors.public.upstream.info("rake")
    assert_equal mirror_fixture("3-oaken", "info/oaken").read, mirrors.public.upstream.info("oaken")

    # then, compact, removing both one gem version and one gem line
    rake_versions.clear
    oaken_versions.delete("0.1.0")
    unpwn_versions = %w[0.1.0 0.2.0 0.3.0 1.0.0 1.0.1]

    stub_rubygems("4-compacted")
    perform_import
    assert_equal rake_versions, mirror_versions("rake")
    assert_equal oaken_versions, mirror_versions("oaken")
    assert_equal unpwn_versions, mirror_versions("unpwn")
    assert_equal mirror_fixture("4-compacted", "versions").read, mirrors.public.upstream.versions
    assert_equal "", mirrors.public.upstream.info("rake")
    assert_equal mirror_fixture("4-compacted", "info/oaken").read, mirrors.public.upstream.info("oaken")
    assert_equal mirror_fixture("4-compacted", "info/unpwn").read, mirrors.public.upstream.info("unpwn")
  end

private

  def perform_import
    Rails.cache.clear
    Namespace::Mirror::Upstream.memory_store.clear
    mirrors.public.import
    perform_enqueued_jobs
  end

  def mirror_versions(name)
    rake = namespaces.public.external_index.gems.find_by(name:)
    rake ? rake.versions.pluck(:ref).sort : []
  end

  def stub_rubygems(scenario)
    dir = Rails.root.join("test/fixtures/files/mirror").join(scenario)
    stub_request(:get, "https://rubygems.org/versions").
      to_return(body: dir.join("versions").open)
    dir.glob("info/*").each do |file|
      stub_request(:get, "https://rubygems.org/info/#{file.basename}").
        to_return(body: file.open)
    end
    dir.glob("api/v1/versions/*").each do |file|
      stub_request(:get, "https://rubygems.org/api/v1/versions/#{file.basename}").
        to_return(body: file.open, headers: {"content-type": "application/json"})
    end
  end

  def mirror_fixture(scenario, file)
    Rails.root.join("test/fixtures/files/mirror").join(scenario).join(file)
  end
end
