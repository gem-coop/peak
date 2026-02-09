require "test_helper"

class Namespaces::GemsControllerTest < ActionDispatch::IntegrationTest
  test "show with missing gem" do
    head namespaces_gems_url(namespace: namespaces.gemcoop, id: "nonexistent-1.0.0.gem")
    assert_response :not_found
  end

  test "get show with redirect" do
    version = versions.by gems.oaken, ref: "0.9.1"

    head namespaces_gems_url(namespace: namespaces.gemcoop, id: version)
    assert_redirected_to "https://gem.coop/gems/oaken-0.9.1.gem"
  end

  test "get show with upload" do
    get namespaces_gems_url(namespace: namespaces.gemcoop, id: gems.peak.versions.first)
    assert_response :success

    upload = Peak::Gem::Upload.read(StringIO.new(response.body))
    assert upload.spec
  ensure
    upload.unlink
  end

  test "push" do
    sign_in users.plain
    package = file_fixture "peak/peak-0.2.0.gem"

    refute references.type.exists?(name: "second_release_exclusive_ref")

    assert_increments gems.peak.versions do
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread, authorization: user.create_push_key.token }
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
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread, authorization: "" }
    end
    assert_response :unauthorized
    assert_dom "body", /API Key/

    sign_in users.plain
    host! "example.com/nonexistent"

    refute_increments gems.peak.versions do
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread, authorization: user.create_push_key.token }
    end
    assert_response :unauthorized
    assert_dom "body", /User doesn't/
  end

  test "push with expired API key" do
    token = users.plain.create_push_key.token
    package = file_fixture "peak/peak-0.2.0.gem"

    travel 24.hours + 1.second

    refute_increments gems.peak.versions do
      post gem_push_url, env: { "RAW_POST_DATA" => package.binread, authorization: token }
    end
    assert_response :unauthorized
    assert_dom "body", /API Key/
  end
end
