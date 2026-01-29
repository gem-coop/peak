class CooldownVersion < ApplicationRecord
  default_scope -> { where(yanked_at: nil) }
  scope :cooled, -> { where("published_at < ?", 48.hours.ago).order(:published_at) }

  def self.import
    versions = Server.versions
    versions_byte = 0

    cv = CooldownVersion.order(:versions_byte).last
    cv_line = cv && Server.versions_until(cv.versions_byte).lines.last
    # jump to our last known version if it's still good
    if cv_line && cv_line.starts_with?(cv.name) && cv_line.include?(cv.version) && cv_line.ends_with?("\n")
      versions_byte = cv.versions_byte
    end

    cv_jobs = versions[versions_byte..].lines.map do |version_line|
      versions_byte += version_line.size
      next if version_line.match(/^created_at:|^---/)
      CooldownVersionLineImportJob.new(versions_byte, version_line)
    end.compact

    ActiveJob.perform_all_later(cv_jobs)
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

    info_byte = 0
    info = Server.info(name)
    cvs = info[info_byte..].lines.map do |info_line|
      info_byte += info_line.size
      next if info_line.match(/^created_at:|^---/)
      version, _ = info_line.split(" ", 2)
      next unless vset.include?(version)
      {name:, version:, versions_byte:, info_byte:}
    end.compact

    versions = Server.versions_json(name)
    cvs.each do |cv|
      v = versions.find { |v| cv[:version] == v["number"] }
      cv[:published_at] = v["created_at"]
    end

    CooldownVersion.upsert_all(cvs, unique_by: %i[name version]) unless cvs.empty?
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
