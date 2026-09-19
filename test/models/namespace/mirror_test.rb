require "test_helper"

class Namespace::MirrorTest < ActiveSupport::TestCase
  test "can be created" do
    namespace = namespaces.rubygems
    mirror = namespace.create_mirror!(url: "https://rubygems.org")
    assert mirror.enabled?
  end
end
