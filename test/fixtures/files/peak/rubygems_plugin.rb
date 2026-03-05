require "rubygems"
require "rubygems/command_manager"
require "rubygems/command"

Gem::CommandManager.instance.register_command :coop

class Gem::Commands::CoopCommand < Gem::Command
  def initialize
    super "coop", "Commands to interact with gem.coop"
  end

  def handle_options(args)
    @subcommand = args.shift
    @namespace = args.shift
    @args = args # Sidestep Gem::Command option parsing
  end

  # gem coop release @namespace --platform darwin21 # Calls `gem build`s then `gem push`
  # gem coop push @namespace peak-0.1.0.gem # Wraps `gem push`
  def execute
    ENV.fetch("GEM_HOST_API_KEY") { say "Prefix command with your GEM_HOST_API_KEY= to push gems"; exit 1 }

    case subcommand
    when "release-dev" then release_dev
    when "release" then release
    when "push" then push(package_path: @args.first)
    else
      raise ArgumentError, "unknown subcommand"
    end
  end

  private
    attr_reader :subcommand, :namespace, :args

    def release_dev
      require "fileutils"
      require "rubygems/specification"
      require "rubygems/commands/build_command"

      @namespace += "/dev"

      build = Gem::Commands::BuildCommand.new
      path = args.first && build.find_gemspec(args.first) || build.find_gemspec

      spec = Gem::Specification.load path
      sha = `git rev-parse --short head`.chomp
      date = Time.now.strftime("%Y.%m.%d")
      spec.version = version = "#{spec.version}.#{sha}.#{date}"

      FileUtils.mkdir_p "pkg"
      build_path = "pkg/#{spec.name}-#{version}.gemspec"
      File.binwrite build_path, spec.to_ruby

      package_path = build.invoke build_path, *args # Haven't figured out how to get options[:build_path] to trigger so we Dir.chdir internally.
      push(package_path:)
    end

    def release
      require "rubygems/commands/build_command"
      build = Gem::Commands::BuildCommand.new
      package_path = build.invoke *args # Haven't figured out how to get options[:build_path] to trigger so we Dir.chdir internally.

      push(package_path:)
    end

    def push(package_path: args.first)
      require "rubygems/commands/push_command"
      push = Gem::Commands::PushCommand.new
      push.invoke package_path, "--host", "http://peak.test/#{namespace}" # "https://#{"beta." if beta?}gem.coop/#{namespace}"
    end

    def beta? = true # Add as an option or just don't host gem pushing on beta.?
end
