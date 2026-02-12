class Peak::Command
  def self.gem_push(key, host)
    "GEM_HOST_API_KEY=#{key} gem push --host #{host}"
  end

  def self.rake_release(key, host)
    "GEM_HOST_API_KEY=#{key} RUBYGEMS_HOST=#{host} rake release"
  end
end
