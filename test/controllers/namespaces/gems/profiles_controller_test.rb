require "test_helper"

class Namespaces::Gems::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_dom "section li", /#{gems.peak.versions.first.ref}/
  end

  # A stored unsafe link must render as inert text; safe http(s) links stay clickable.
  test "renders unsafe stored links as text, not anchors" do
    gems.peak.versions.pure.latest.links.create!(key: "homepage", value: "javascript:alert(1)")

    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_no_match(/href="javascript:/, response.body)
    assert_dom "a[href='https://github.com/gem-coop/peak']"
  end
end
