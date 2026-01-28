class CooldownVersion < ApplicationRecord
  default_scope -> { where(yanked_at: nil) }
  scope :cooled, -> { where("published_at < ?", 48.hours.ago).order(:published_at) }

  def self.import(import_async = false)
    versions = Server.versions
    versions_byte = 0

    cv = CooldownVersion.order(:versions_byte).last
    cv_line = cv && Server.versions_until(cv.versions_byte).lines.last
    # jump to our last known version if it's still good
    if cv_line && cv_line.starts_with?(cv.name) && cv_line.include?(cv.version) && cv_line.ends_with?("\n")
      versions_byte = cv.versions_byte
    end

    cv_jobs = from_contentful_lines_in versions, offset: versions_byte do |pos, line|
      CooldownVersionLineImportJob.new(pos, line)
    end

    if import_async
      ActiveJob.perform_all_later(cv_jobs)
    else
      cv_jobs.each(&:perform_now)
    end
  end

  def self.import_line(versions_byte, version_line)
    name, vset, _ = version_line.split(" ", 3)
    vset = Set.new(vset.split(","))

    # Handle lines that are just yanks
    if vset.size == 1 && vset.first.starts_with?("-")
      version = vset.first[1..]
      cvs = [{name:, version:, yanked_at: Time.now}]
      return CooldownVersion.unscoped.upsert_all(cvs, unique_by: %i[name version])
    end

    cvs = from_contentful_lines_in Server.info(name) do |pos, line|
      version, = line.split(" ", 2)
      {name:, version:, versions_byte:, info_byte: pos} unless vset.add?(version)
    end

    versions = Server.versions_json(name)
    cvs.each do |cv|
      v = versions.find { |v| cv[:version] == v["number"] }
      cv[:published_at] = v["created_at"]
    end

    CooldownVersion.upsert_all(cvs, unique_by: %i[name version]) unless cvs.empty?
  end

  def self.from_contentful_lines_in(string, offset: 0)
    io = StringIO.new(string).tap { _1.seek offset }
    io.each_line.filter_map do |line|
      next if line.start_with? "created_at:", "---"
      yield io.pos, line
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
