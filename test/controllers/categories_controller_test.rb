require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  test "get index" do
    get categories_path
    assert_response :success
    assert_dom "h3", "Active Record Plugins"
    assert_aria_current_page "ALL"
  end

  test "get index with letter" do
    get categories_path(l: "B")
    assert_response :success
    assert_dom "h3", "Background Processing"
    assert_aria_current_page "B"
  end

  test "get index with non-existent letter" do
    get categories_path(l: "Ø")
    assert_response :success
    assert_dom "h3", "Active Record Plugins"
    assert_aria_current_page "ALL"
  end

  test "get show" do
    namespaces.rubygems.gems.where(name: :activesupport).update_all name: :active_flag

    get category_path("Active_Record_Bit_Fields")
    assert_response :success
    assert_dom "a[href='https://ruby-toolbox.com/categories/Active_Record_Bit_Fields']"
    assert_dom "article h4", "active_flag"
    assert_dom "section span", "None."
  end

  test "get show empty" do
    get category_path("Active_Record_Bit_Fields")
    assert_response :success
    assert_dom "a[href='https://ruby-toolbox.com/categories/Active_Record_Bit_Fields']"

    assert_dom "section span", text: "None.", count: 2
  end

  test "get show with no versions 200s" do
    get category_path("Active_Record_Bit_Fields")
    assert_response :success
    assert_dom "a[href='https://ruby-toolbox.com/categories/Active_Record_Bit_Fields']"
  end

  test "get show with non-existent category" do
    get category_path("lol")
    assert_redirected_to categories_path
  end

  private
    def assert_aria_current_page(text)
      assert_dom "a[aria-current='page']", count: 1 do |anchor|
        assert_equal text, anchor.text
      end
    end
end
