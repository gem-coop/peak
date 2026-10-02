require "test_helper"

class Namespace::Gem::ImportsTest < ActiveSupport::TestCase
  def gem = @gem ||= gems.create(:imports_test, name: "imports-test", namespace: namespaces.gemcoop).reload
  def imports = gem.imports
  def index = namespaces.gemcoop.stable_index

  def stub_server(info:, versions:)
    stub_request(:get, "https://rubygems.org/info/imports-test").
      to_return(status: 200, body: info)
    stub_request(:get, "https://rubygems.org/api/v1/versions/imports-test.json").
      to_return(status: 200, body: JSON.dump(versions), headers: { "content-type" => "application/json" })
  end

  def stub_gemspec(ref, name: "imports-test", version: ref, platform: nil)
    stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/#{name}-#{ref}.gemspec.rz").
      to_return(status: 200, body: gemspec_payload(name:, version:, platform:))
  end

  def gemspec_payload(name:, version:, summary: "summary", platform: nil)
    spec = Gem::Specification.new do |s|
      s.name = name
      s.version = version
      s.summary = summary
      s.authors = ["author"]
      s.files = []
      s.platform = platform if platform
    end
    Gem.deflate Marshal.dump(spec)
  end

  def versions_json(*refs)
    refs.map { |ref|
      { "number" => ref, "platform" => "ruby", "created_at" => "2024-01-01T00:00:00.000Z", "sha" => "checksum-#{ref}" }
    }
  end

  test "imports refs the server has that we don't" do
    stub_server info: "---\n1.0.0 |checksum:a\n", versions: versions_json("1.0.0")
    stub_gemspec "1.0.0"

    assert_increments gem.versions do
      imports.import_all(index)
    end

    version = versions.by gem, ref: "1.0.0"
    assert_equal index, version.index
    assert_equal Peak.system_user, version.created_by
    assert_equal "summary", version.summary
    assert_equal "checksum-1.0.0", version.checksum
    assert_equal Time.utc(2024, 1, 1), version.published_at
    assert_match "checksum:checksum-1.0.0", version.metadata.line
    assert_match "published_at:2024-01-01T00:00:00.000Z", version.metadata.line
  end

  test "does nothing when the server and stored refs match" do
    stub_server info: "---\n1.0.0 |checksum:a\n", versions: versions_json("1.0.0")
    stub_gemspec "1.0.0"
    imports.import_all(index)

    refute_increments gem.versions do
      imports.import_all(index)
    end
  end

  test "yanks refs we have that the server no longer has" do
    stub_server info: "---\n1.0.0 |checksum:a\n1.1.0 |checksum:b\n", versions: versions_json("1.0.0", "1.1.0")
    stub_gemspec "1.0.0"
    stub_gemspec "1.1.0"
    imports.import_all(index)
    assert_equal %w[1.0.0 1.1.0], gem.reload.versions.map(&:ref)

    # The server has yanked 1.0.0.
    stub_server info: "---\n1.1.0 |checksum:b\n", versions: versions_json("1.1.0")
    assert_decrements gem.versions do
      imports.import_all(index)
    end

    assert_equal %w[1.1.0], gem.reload.versions.map(&:ref)
  end

  test "reindexes the gem after importing" do
    stub_server info: "---\n1.0.0 |checksum:a\n", versions: versions_json("1.0.0")
    stub_gemspec "1.0.0"

    imports.import_all(index)

    assert_equal "imports-test summary", gem.reload.search_index.content
  end

  test "ignores the known-broken refs for a gem" do
    gem = gems.create(:sevgi_derender, name: "sevgi-derender", namespace: namespaces.gemcoop).reload

    stub_request(:get, "https://rubygems.org/info/sevgi-derender").
      to_return(status: 200, body: "---\n0.73.0 |checksum:broken\n0.73.1 |checksum:ok\n")
    stub_request(:get, "https://rubygems.org/api/v1/versions/sevgi-derender.json").
      to_return(status: 200, body: JSON.dump(versions_json("0.73.0", "0.73.1")), headers: { "content-type" => "application/json" })
    stub_gemspec "0.73.1", name: "sevgi-derender"

    assert_increments gem.versions do
      gem.imports.import_all(index)
    end

    refute_requested :get, "https://rubygems.org/quick/Marshal.4.8/sevgi-derender-0.73.0.gemspec.rz"
    assert_equal %w[0.73.1], gem.reload.versions.map(&:ref)
  end

  test "maps platform-specific refs through the publishing ledger" do
    stub_request(:get, "https://rubygems.org/info/imports-test").
      to_return(status: 200, body: "---\n1.0.0-x86_64-linux |checksum:a\n")
    stub_request(:get, "https://rubygems.org/api/v1/versions/imports-test.json").
      to_return(status: 200, headers: { "content-type" => "application/json" },
        body: JSON.dump([{ "number" => "1.0.0", "platform" => "x86_64-linux", "created_at" => "2024-01-01T00:00:00.000Z", "sha" => "checksum-a" }]))
    stub_gemspec "1.0.0-x86_64-linux", version: "1.0.0", platform: "x86_64-linux"

    imports.import_all(index)

    version = versions.by gem, ref: "1.0.0-x86_64-linux"
    assert_equal Peak::Platform.find_by(key: "x86_64-linux"), version.platform
    assert_equal "checksum-a", version.checksum
    assert_equal Time.utc(2024, 1, 1), version.published_at
  end

  test "raises with the accumulated errors, keeping the refs that did import" do
    stub_server info: "---\n1.0.0 |checksum:a\n1.1.0 |checksum:b\n1.2.0 |checksum:c\n",
      versions: versions_json("1.0.0", "1.1.0", "1.2.0")
    stub_gemspec "1.0.0"
    %w[1.1.0 1.2.0].each do |ref|
      stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/imports-test-#{ref}.gemspec.rz").
        to_return(status: 404, body: "")
    end

    error = assert_raises(RuntimeError) { imports.import_all(index) }

    # Errors are accumulated per-ref as `"#{ref}: #{error.inspect}\n"`.
    assert_equal 2, error.message.lines.size
    assert_match(/\A1\.1\.0: #<.+>\n\z/, error.message.lines.first)
    assert_match(/\A1\.2\.0: #<.+>\n\z/, error.message.lines.last)

    # The ref that did import before the failures is kept.
    assert_equal %w[1.0.0], gem.reload.versions.map(&:ref)
  end
end
