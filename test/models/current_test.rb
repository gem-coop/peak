require "test_helper"

class CurrentTest < ActiveSupport::TestCase
  test "unlinks uploads" do
    file = Tempfile.new
    assert file.path

    Current.uploads << Peak::Gem::Upload.new(file)
    Current.reset

    assert_nil file.path
  end
end
