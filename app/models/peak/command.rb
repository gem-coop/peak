class Peak::Command
  def self.gem_push(key, host)
    "GEM_HOST_API_KEY=#{key} gem push --host #{host}"
  end

  def self.rake_release(key, host)
    "GEM_HOST_API_KEY=#{key} RUBYGEMS_HOST=#{host} rake release"
  end

  def self.trusted_publisher_workflow(host:, gem:)
    <<~YAML
      name: Release #{gem}
      on:
        push:
          tags: ["v*"]
      permissions:
        id-token: write
        contents: read
      jobs:
        push:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v4
            - uses: ruby/setup-ruby@v1
              with:
                bundler-cache: true
            - uses: rubygems/configure-rubygems-credentials@main
              with:
                gem-server: #{host}
            - run: gem build #{gem}.gemspec
            - run: gem push --host #{host} #{gem}-*.gem
    YAML
  end
end
