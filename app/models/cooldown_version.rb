class CooldownVersion < ApplicationRecord
  default_scope -> { where(yanked_at: nil) }
  scope :cooled, -> { where("published_at < ?", 48.hours.ago).order(:published_at) }

  def self.previous_latest_version = order(:versions_byte).last&.then&.find(&:still_latest?)
  def still_latest?
    # Check if we still appear on the last line read during last import where we left off.
    if line = Server.versions_until(versions_byte).lines.last
      line.starts_with?(name) && line.include?(version) && line.ends_with?("\n")
    end
  end

  def self.import(import_async = false)
    positions = pos_lines_from Server.versions, offset: previous_latest_version&.versions_byte || 0
    jobs = positions.map { |pos, line| CooldownVersionLineImportJob.new pos, line }

    if import_async
      ActiveJob.perform_all_later(jobs)
    else
      jobs.each(&:perform_now)
    end
  end

  def self.import_line(versions_byte, version_line)
    name, vset, _ = version_line.split(" ", 3)
    vset = Set.new(vset.split(","))

    # Handle yank lines that start with -
    if vset.one? && (version = vset.first.dup).delete_prefix!("-")
      return unscoped.upsert({name:, version:, yanked_at: Time.now}, unique_by: %i[name version])
    end

    cvs = pos_lines_from(Server.info(name)).filter_map do |pos, line|
      version, = line.split(" ", 2)
      {name:, version:, versions_byte:, info_byte: pos} unless vset.add?(version)
    end

    versions = Server.versions_json(name).index_by { _1["number"] }
    cvs.each do |cv|
      cv[:published_at] = versions.dig(cv[:version], "created_at")
    end

    CooldownVersion.upsert_all(cvs, unique_by: %i[name version]) unless cvs.empty?
  end

  def self.pos_lines_from(string, offset: 0)
    io = StringIO.new(string).tap { _1.seek offset }
    io.each_line.filter_map do |line|
      [io.pos, line] unless line.start_with? "created_at:", "---"
    end
  end

  module Server
    def self.cached_get(path, expires_in:)
      Rails.cache.fetch(path, expires_in:) { HTTPX.plugin(:brotli).get("https://#{path}").to_s }
    end

    def self.versions
      cached_get("gem.coop/versions", expires_in: 5.minutes)
    end

    def self.versions_until(byte)
      versions.byteslice(...byte)
    end

    def self.info(name)
      cached_get("gem.coop/info/#{name}", expires_in: 5.minutes)
    end

    def self.info_until(name, byte)
      info(name).byteslice(...byte)
    end

    def self.versions_json(name)
      JSON.parse cached_get("rubygems.org/api/v1/versions/#{name}.json", expires_in: 30.minutes)
    end
  end
end
