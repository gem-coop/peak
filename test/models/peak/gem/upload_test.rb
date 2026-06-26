require "test_helper"
require "tmpdir"
require "fileutils"
require "rubygems/package"
require "rubygems/user_interaction"

class Peak::Gem::UploadTest < ActiveSupport::TestCase
  # A crafted gem can preserve `javascript:`/`data:` link schemes; only http(s) links must survive.
  test "links drops unsafe URI schemes and keeps web links" do
    payload = build_crafted_gem(
      homepage: "javascript:alert(1)",
      metadata: {
        "source_code_uri" => "https://example.com/src",
        "bug_tracker_uri" => "javascript:alert(2)",
        "changelog_uri"   => "data:text/html,evil"
      }
    )

    upload = Peak::Gem::Upload.read(StringIO.new(payload))

    assert_equal({ source_code: "https://example.com/src" }, upload.links)
  ensure
    upload&.unlink
  end

  private
    # Builds a `.gem` via RubyGems' skip-validation path so unsafe links survive into the spec.
    def build_crafted_gem(**spec_attrs)
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          FileUtils.mkdir_p("lib")
          File.write("lib/x.rb", "module X; end\n")

          spec = Gem::Specification.new do |s|
            s.name = "safe"
            s.version = "1.0.0"
            s.summary = "summary"
            s.author = "author"
            s.files = ["lib/x.rb"]
            spec_attrs.each { |key, value| s.public_send("#{key}=", value) }
          end

          path = Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) do
            Gem::Package.build(spec, true, false)
          end
          File.binread(path)
        end
      end
    end
end
