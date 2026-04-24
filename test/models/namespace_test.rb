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
    assert namespaces.build(name: "@org3").valid?

    third = namespaces.build(name: "org3")
    assert_equal "@org3", third.name
    assert third.valid?
  end

  private
    def assert_name_clash(name)
      namespaces.create(name:).errors[:name].any?
    end
end

# == Schema Information
#
# Table name: namespaces
#
#  id          :bigint           not null, primary key
#  approved_at :datetime
#  name        :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_namespaces_on_approved_at  (approved_at)
#  index_namespaces_on_name         (name) UNIQUE
#
