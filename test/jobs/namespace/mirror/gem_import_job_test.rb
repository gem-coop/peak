require "test_helper"

class Namespace::Mirror::GemImportJobTest < ActiveSupport::TestCase
  def stub_rake
    stub_request(:get, "https://rubygems.org/info/rake").
      to_return(status: 200, body: <<~END)
        ---
        13.3.0 |checksum:96f5092d786ff412c62fde76f793cc0541bd84d2eb579caa529aa8a059934493,ruby:>= 2.3
      END
    stub_request(:get, "https://rubygems.org/api/v1/versions/rake.json").
      to_return(status: 200, body: file_fixture("rake.json"), headers: {'content-type': "application/json"})
    stub_request(:get, "https://rubygems.org/quick/Marshal.4.8/rake-13.3.0.gemspec.rz").
      to_return(status: 200, body: file_fixture("gemspecs/quick/rake-13.3.0.gemspec.rz"))
  end

  test "imports the gem's versions" do
    stub_rake
    gem = namespaces.rubygems.gems.create!(name: "rake")

    Namespace::Mirror::GemImportJob.new.perform(name: "rake", namespace_id: namespaces.rubygems.id)

    assert_equal %w[13.3.0], gem.reload.versions.map(&:ref)
  end

  test "only looks in the namespace it was given" do
    namespaces.rubygems.gems.create!(name: "rake")

    assert_raises ActiveRecord::RecordNotFound do
      Namespace::Mirror::GemImportJob.new.perform(name: "rake", namespace_id: namespaces.gemcoop.id)
    end
  end
end
