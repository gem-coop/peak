require "test_helper"
require_relative "../support/gem_server_client"
require_relative "../support/namespace_provisioning"

class PublishingTest < ActionDispatch::IntegrationTest
  include GemServerClient, NamespaceProvisioning
  setup { Rails.application.config.action_controller.cache_store.clear }

  test "a published gem is served by every read API" do
    publisher = provision_publisher "@ada", as: "ada@example.com"
    package = file_fixture("peak/peak-0.1.0.gem").binread

    publish publisher, package

    namespace = publisher.namespace
    assert_equal ["0.1.0"], compact_index_versions(namespace)["peak"]
    assert_equal ["0.1.0"], compact_index_info(namespace, "peak")

    version = published_version namespace, "peak", "0.1.0"
    assert_equal "peak", fetch_gem(namespace, version).name
    assert_equal package, download_gem(namespace, version), "the served gem is byte-for-byte what was pushed"

    assert_equal %w[stable], namespace.indexes.pluck(:slug)
    assert_equal ["0.1.0"], compact_index_versions(namespace, index: "stable")["peak"],
      "the index serves the gem under its own slug too"
  end

  test "a second version joins the first across the APIs" do
    publisher = provision_publisher "@ben", as: "ben@example.com"
    namespace = publisher.namespace

    publish publisher, file_fixture("peak/peak-0.1.0.gem").binread
    publish publisher, file_fixture("peak/peak-0.2.0.gem").binread

    assert_equal %w[0.1.0 0.2.0], compact_index_versions(namespace)["peak"].sort
    assert_equal %w[0.1.0 0.2.0], compact_index_info(namespace, "peak").sort

    %w[0.1.0 0.2.0].each do |ref|
      version = published_version namespace, "peak", ref
      assert_equal file_fixture("peak/peak-#{ref}.gem").binread, download_gem(namespace, version)
    end

    assert_equal %w[0.1.0 0.2.0], compact_index_versions(namespace, index: "stable")["peak"].sort
  end

  test "a platform build is published alongside the ruby one" do
    publisher = provision_publisher "@cara", as: "cara@example.com"
    namespace = publisher.namespace

    publish publisher, file_fixture("peak/peak-0.1.0.gem").binread
    publish publisher, file_fixture("peak/peak-0.1.0-arm-linux.gem").binread

    assert_equal %w[0.1.0 0.1.0-arm-linux], compact_index_versions(namespace)["peak"].sort
    assert_equal %w[0.1.0 0.1.0-arm-linux], compact_index_info(namespace, "peak").sort

    platform = published_version namespace, "peak", "0.1.0-arm-linux"
    assert_equal Peak::Platform.find_by(key: "arm-linux"), platform.platform
    assert_equal file_fixture("peak/peak-0.1.0-arm-linux.gem").binread, download_gem(namespace, platform)
  end

  test "a second gem shares the namespace without disturbing the first" do
    publisher = provision_publisher "@dee", as: "dee@example.com"
    namespace = publisher.namespace

    publish publisher, file_fixture("peak/peak-0.1.0.gem").binread
    publish publisher, gem_package_from(name: "safe", version: "1.0.0")

    versions = compact_index_versions(namespace)
    assert_equal ["0.1.0"], versions["peak"]
    assert_equal ["1.0.0"], versions["safe"]
    assert_equal ["1.0.0"], compact_index_info(namespace, "safe")

    assert_equal "safe", fetch_gem(namespace, published_version(namespace, "safe", "1.0.0")).name
    assert_equal "peak", fetch_gem(namespace, published_version(namespace, "peak", "0.1.0")).name
  end

  test "pushing to a namespace you do not own is rejected" do
    owner = provision_publisher "@eve", as: "eve@example.com"
    outsider = provision_publisher "@frank", as: "frank@example.com"

    refute_increments Namespace::Gem::Version do
      gem_push owner.namespace, file_fixture("peak/peak-0.1.0.gem").binread, token: outsider.token
    end
    assert_response :unauthorized
    assert_match "doesn't have access", response.body

    assert_empty compact_index_versions(owner.namespace)
  end
end
