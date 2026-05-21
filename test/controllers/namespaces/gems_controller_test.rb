require "test_helper"

class Namespaces::GemsControllerTest < ActionDispatch::IntegrationTest
  def namespace = namespaces.gemcoop
  def token = users.plain.create_push_key.token

  test "show with missing gem" do
    head namespace_gems_url(namespace:, id: "nonexistent-1.0.0.gem")
    assert_response :not_found
  end

  test "get show with redirect" do
    version = versions.by gems.oaken, ref: "0.9.1"

    head namespace_gems_url(namespace:, id: version)
    assert_redirected_to "https://gem.coop/gems/oaken-0.9.1.gem"
  end

  test "get show with upload" do
    get namespace_gems_url(namespace:, id: gems.peak.versions.first)
    assert_response :success

    upload = Peak::Gem::Upload.read(StringIO.new(response.body))
    assert upload.spec
  ensure
    upload.unlink if upload # Guard against never reaching the assignment line
  end

  test "push" do
    package = file_fixture "peak/peak-0.2.0.gem"

    refute references.type.exists?(name: "second_release_exclusive_ref")

    assert_increments gems.peak.versions do
      post namespace_gem_push_url(namespace:), env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{token}" }
    end
    assert_response :success
    refute_empty response.body, "bundler throws an exception in case there's no text in the response"
    assert_match "peak-0.2.0.gem uploaded 🎉", response.body

    version = versions.by gems.peak, ref: "0.2.0"
    assert_equal users.plain, version.created_by

    assert_equal "peak-0.2.0", version.name
    assert_equal ">= 4.0", version.ruby
    assert_equal ">= 2.7", version.rubygems
    assert_equal ["peak"], version.executables
    assert version.has_extensions?
    assert_equal ["MIT"], version.licenses

    assert_equal Date.current, version.published_at.to_date
    assert_equal "c6de6896567dd0fc5d000712cb75d12b4ef6168d1e340b9531523dcad9e50937", version.checksum

    assert_equal version.line, version.compute_line

    version.line.split("|", 2).tap do |references, metadata|
      assert references && metadata
      assert_match "oaken:>= 0.9&~> 1.0.0,second_release_exclusive_ref:= 2.0", references
      assert_match "checksum:#{version.checksum},ruby:>= 4.0,rubygems:>= 2.7,executables:peak,licenses:MIT,published_at:#{version.published_at.iso8601(3)}\n", metadata
    end

    assert_equal({
      homepage: "https://github.com/gem-coop/peak",
      documentation: "https://github.com/gem-coop/peak",
      source_code: "https://github.com/gem-coop/peak",
      changelog: "https://github.com/gem-coop/peak/blob/main/CHANGELOG.md",
      bug_tracker: "https://github.com/gem-coop/peak/issues",
      mailing_list: "https://github.com/gem-coop/peak",
      somewhere_custom: "https://github.com/gem-coop/peak"
    }, version.links.pluck(:key, :value).to_h.symbolize_keys)

    assert version.package.attached?
    assert_equal package.binread, version.package.download

    first = versions.by gems.peak, ref: "0.1.0"
    assert_equal first.references.line, version.references.where.not(name: "second_release_exclusive_ref").line
    assert_equal users.owner, first.created_by
  end

  test "push platform" do
    package = file_fixture "peak/peak-0.1.0-arm-linux.gem"

    assert_increments gems.peak.versions do
      post namespace_gem_push_url(namespace:), env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{token}" }
    end
    assert_response :success
    refute_empty response.body, "bundler throws an exception in case there's no text in the response"
    assert_match "peak-0.1.0-arm-linux.gem uploaded 🎉", response.body

    version = versions.by gems.peak, ref: "0.1.0-arm-linux"
    assert_equal users.plain, version.created_by

    assert_equal "peak-0.1.0-arm-linux", version.name
    assert_equal ">= 4.0", version.ruby
    assert_equal ">= 2.7", version.rubygems
    assert_equal ["peak"], version.executables
    assert version.has_extensions?
    assert_equal ["MIT"], version.licenses
    assert_equal Peak::Platform.find_by(key: "arm-linux"), version.platform
    assert_equal "oaken:>= 0.9&~> 1.0.0", version.references.line

    assert_equal({
      homepage: "https://github.com/gem-coop/peak",
      documentation: "https://github.com/gem-coop/peak",
      source_code: "https://github.com/gem-coop/peak",
      changelog: "https://github.com/gem-coop/peak/blob/main/CHANGELOG.md",
      bug_tracker: "https://github.com/gem-coop/peak/issues",
      mailing_list: "https://github.com/gem-coop/peak",
      somewhere_custom: "https://github.com/gem-coop/peak"
    }, version.links.pluck(:key, :value).to_h.symbolize_keys)

    assert_equal Date.current, version.published_at.to_date
    assert_equal "515d221c58bb6d91d5b8e09a76db525db9f2d62cb4d7a39a6d80b602970c350f", version.checksum

    assert version.package.attached?
    assert_equal package.binread, version.package.download

    first = versions.by gems.peak, ref: "0.1.0"
    assert_equal first.references.line, version.references.line
    assert_equal users.owner, first.created_by
  end

  test "push with invalid API key" do
    package = file_fixture "peak/peak-0.2.0.gem"

    refute_increments gems.peak.versions do
      post namespace_gem_push_url(namespace:), env: { "RAW_POST_DATA" => package.binread, authorization: "" }
    end
    assert_response :unauthorized
    assert_dom "body", /API Key/

    refute_increments gems.peak.versions do
      post namespace_gem_push_url(namespace: "@nonexistent"), env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{token}" }
    end
    assert_response :unauthorized
    assert_dom "body", /User doesn't/
  end

  test "push with expired API key" do
    token = users.plain.create_push_key(expires_at: 1.hour.ago).token
    package = file_fixture "peak/peak-0.2.0.gem"

    refute_increments gems.peak.versions do
      post namespace_gem_push_url(namespace:), env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{token}" }
    end
    assert_response :unauthorized
    assert_dom "body", /API Key/
  end
end
