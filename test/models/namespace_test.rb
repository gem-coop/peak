require "test_helper"

class NamespaceTest < ActiveSupport::TestCase
  test "name" do
    assert_equal "@gemcoop", namespaces.gemcoop.name
  end

  test "name format" do
    assert_name_clash "@gemcoop"

    assert namespaces.build(name: "gemcoop").invalid?
    assert namespaces.build(name: "@Gemcoop").invalid?
    # assert namespaces.build(name: "@gem-coop").invalid? # TODO: get this working

    assert namespaces.build(name: "@org-rb").valid?
  end

  private
    def assert_name_clash(name)
      assert_raises ActiveRecord::RecordNotUnique do
        Namespace.create name:
      end
    end
end
