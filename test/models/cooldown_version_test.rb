require "test_helper"

class CooldownVersionTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").to_return(
      body: file_fixture("rake.json").open, headers: {"content-type": "application/json"})

    stub_request(:get, "https://rubygems.org/api/v1/versions/nokogiri.json").to_return(
      body: file_fixture("nokogiri.json").open, headers: {"content-type": "application/json"})
  end

  test "import works" do
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").read.lines[0...-4].join)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").read.lines[0...-3].join)
    stub_request(:get, "https://gem.coop/info/nokogiri").to_return(body: file_fixture("info/nokogiri").read)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    assert_equal 94, CooldownVersion.count
    last = CooldownVersion.last
    assert_equal "rake", last.name
    assert_equal "13.2.0", last.version
    assert_equal 894, last.versions_byte
    assert_equal 9535, last.info_byte

    versions = CooldownVersion::Server.versions_until(last.versions_byte)
    assert_equal 894, versions.size
    assert_includes versions, "13.2.0"
    assert_not_includes versions, "13.2.1"

    info = CooldownVersion::Server.info_until(last.name, last.info_byte)
    assert_equal 9535, info.size
    assert_includes info, "13.2.0"
    assert_not_includes info, "13.2.1"

    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").read)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").read)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    # get the whole file if we don't have a byte offset
    assert_equal file_fixture("versions").read, CooldownVersion::Server.versions
    assert_equal file_fixture("info/rake").read, CooldownVersion::Server.info("rake")

    assert_equal 97, CooldownVersion.unscoped.count
    assert_equal 96, CooldownVersion.count
    last = CooldownVersion.last
    assert_equal "rake", last.name
    assert_equal "13.3.0", last.version
    assert_equal 984, last.versions_byte
    assert_equal 9723, last.info_byte
    assert_equal [894, 939, 984, 150], CooldownVersion.pluck(:versions_byte).to_a.uniq

    versions = CooldownVersion::Server.versions_until(last.versions_byte)
    assert_equal 984, versions.size
    assert_includes versions, "13.2.1"
    assert_includes versions, "13.3.0"

    info = CooldownVersion::Server.info_until(last.name, last.info_byte)
    assert_equal 9723, info.size
    assert_includes info, "13.2.1"
    assert_includes info, "13.3.0"
  end

  test "import handles compaction" do
    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions").open)
    stub_request(:get, "https://gem.coop/info/rake").to_return(body: file_fixture("info/rake").open)
    stub_request(:get, "https://gem.coop/info/nokogiri").to_return(body: file_fixture("info/nokogiri").open)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    # check the full files match
    assert_equal file_fixture("versions").read, CooldownVersion::Server.versions
    assert_equal file_fixture("info/rake").read, CooldownVersion::Server.info("rake")
    assert_equal file_fixture("info/nokogiri").read, CooldownVersion::Server.info("nokogiri")

    # check the most recent version matches
    assert_equal 97, CooldownVersion.unscoped.count
    assert_equal 96, CooldownVersion.count
    last = CooldownVersion.last
    assert_equal "rake", last.name
    assert_equal "13.3.0", last.version
    assert_equal 984, last.versions_byte
    assert_equal 9723, last.info_byte
    assert_equal [894, 939, 984, 150], CooldownVersion.pluck(:versions_byte).to_a.uniq

    stub_request(:get, "https://gem.coop/versions").to_return(body: file_fixture("versions.compacted").open)
    Rails.cache.clear
    CooldownVersion.import
    perform_enqueued_jobs

    # check the full files match
    assert_equal file_fixture("versions.compacted").read, CooldownVersion::Server.versions
    assert_equal file_fixture("info/rake").read, CooldownVersion::Server.info("rake")

    assert_equal 97, CooldownVersion.count
    last = CooldownVersion.last
    assert_equal "rake", last.name
    assert_equal "13.3.1", last.version
    assert_equal 927, last.versions_byte
    assert_equal 9817, last.info_byte
    assert_equal [908, 150, 927], CooldownVersion.pluck(:versions_byte).to_a.uniq
  end
end
