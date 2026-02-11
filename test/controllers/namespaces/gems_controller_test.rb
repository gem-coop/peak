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
    assert_equal "peak-0.2.0", version.name
    assert_equal ">= 4.0", version.ruby
    assert_equal ">= 2.7", version.rubygems
    assert_equal ["peak"], version.executables
    assert_equal ["MIT"], version.licenses
    assert_equal "oaken:>= 0.9&~> 1.0.1,second_release_exclusive_ref:= 2.0", version.references.line
    assert_equal Date.today, version.published_at.to_date
    assert_equal "a3dcf5a06581a9c8bcae19411852850851f20268614b151ec2484d0c09d44730", version.checksum
    assert version.package.attached?
    assert_equal package.binread, version.package.download

    first = versions.by gems.peak, ref: "0.1.0"
    assert_equal first.references.line, version.references.where.not(name: "second_release_exclusive_ref").line
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
