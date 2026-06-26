require "test_helper"

class Namespaces::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "get show" do
    get namespace_url(namespaces.gemcoop)
    assert_response :success
    assert_dom "article", Regexp.new(gems.oaken.name)
  end

  test "get show with no gems" do
    get namespace_url(namespaces.blank)
    assert_response :success

    namespaces.blank.default_index.gems.create name: "unversioned"

    get namespace_url(namespaces.blank)
    assert_response :success
    assert_not_dom "article", "unversioned"
  end

  test "shows each gem's latest version only" do
    get namespace_url(namespaces.gemcoop)
    assert_response :success
    assert_match "1.0.0", response.body            # oaken latest
    assert_no_match(/0\.9\.1/, response.body)      # not the older version
  end

  # The version lookup must not scale with the number of gems (was one query per gem).
  test "loads latest versions in a bounded number of queries" do
    index = namespaces.blank.default_index

    add_versioned_gems index, %w[aa bb]
    small = count_version_queries { get namespace_url(namespaces.blank) }
    assert_response :success

    add_versioned_gems index, %w[cc dd ee]
    large = count_version_queries { get namespace_url(namespaces.blank) }
    assert_response :success

    assert_equal small, large, "version queries should not grow with gem count"
  end

  private
    def add_versioned_gems(index, names)
      names.each do |name|
        versions.create(gem: index.gems.create!(name:), ref: "1.0.0", line: "")
      end
    end

    def count_version_queries
      count = 0
      counter = ->(*, payload) { count += 1 if payload[:sql] =~ /FROM\s+"?namespace_gem_versions"?/ }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") { yield }
      count
    end
end
