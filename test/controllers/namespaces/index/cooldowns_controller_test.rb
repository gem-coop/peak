require "test_helper"

class Namespaces::Index::CooldownsControllerTest < ActionDispatch::IntegrationTest
  test "get primary index cooldown" do
    get namespace_cooldown_versions_url(namespace:)
    assert_response :success
  end

  test "get primary index cooldown with no cooldowns" do
    namespace.default_index.cooldowns.delete_all

    get namespace_cooldown_versions_url(namespace:)
    assert_response :not_found
  end

  test "get primary index cooldown implicit route order consistency if a second cooldown is created" do
    cooldowns.gemcoop.index.cooldowns.create(interval: 1.day)

    get namespace_cooldown_versions_url(namespace:)
    assert_response :success
    assert_equal cooldowns.gemcoop.contents, response.body
  end

  test "get secondary index cooldown with period_id" do
    get namespace_cooldown_versions_url(namespace:, index: :dev, period_id:)
    assert_response :success
  end

  test "get show" do
    get namespace_cooldown_info_url(namespace:, id: gems.oaken)
    assert_response :success
  end

  test "get show secondary index cooldown with period_id" do
    get namespace_cooldown_info_url(namespace:, index: :dev, period_id:, id: gems.oaken)
    assert_response :not_found
  end

  def namespace = namespaces.gemcoop
  def period_id = "#{cooldowns.gemcoop_dev.interval.in_days.to_i}d"
end
