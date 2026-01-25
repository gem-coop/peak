class CooldownVersion < ApplicationRecord
  scope :cooled, -> { where("published_at < ?", 48.hours.ago).order(:published_at) }

  def self.import(import_async = false)
    versions = versions_until(nil)
    versions_byte = 0

    # cv = CooldownVersion.order(:versions_byte).last
    # cv_line = cv && versions[...cv.versions_byte]&.lines&.last
    # # jump to our last known version if it's still good
    # if cv_line && cv_line.starts_with?(cv.name) && cv_line.include?(cv.version)
    #   versions_byte = cv.versions_byte
    # end

    cv_jobs = versions[versions_byte..].lines.map do |version_line|
      versions_byte += version_line.size
      next if version_line.match(/^created_at:|^---/)
      CooldownVersionLineImportJob.new(versions_byte, version_line)
    end.compact

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
      yank_version = vset.first[1..]
      return CooldownVersion.where(name: name, version: yank_version).destroy_all
    end

    info_byte = 0
    info = info_until(name, nil)
    cvs = info[info_byte..].lines.map do |info_line|
      info_byte += info_line.size
      next if info_line.match(/^created_at:|^---/)
      version, _ = info_line.split(" ", 2)
      next unless vset.include?(version)
      {name:, version:, versions_byte:, info_byte:}
    end.compact

    versions = versions_json(name)
    cvs.each do |cv|
      v = versions.find { |v| cv[:version] == v["number"] }
      cv[:published_at] = v["created_at"]
    end

    CooldownVersion.upsert_all(cvs, unique_by: %i[name version]) unless cvs.empty?
  end

  def self.versions_until(byte)
    versions = Rails.cache.fetch("gem.coop/versions", expires_in: 1.hour) do
      HTTPX.plugin(:brotli).get("https://gem.coop/versions").to_s
    end
    byte ? versions[...byte] : versions
  end

  def self.info_until(name, byte)
    info = Rails.cache.fetch("gem.coop/info/#{name}", expires_in: 1.hour) do
      HTTPX.plugin(:brotli).get("https://gem.coop/info/#{name}").to_s
    end
    byte ? info[...byte] : info
  end

  def self.versions_json(name)
    versions_json = Rails.cache.fetch("rubygems.org/api/v1/versions/#{name}.json", expires_in: 1.hour) do
      HTTPX.plugin(:brotli).get("https://rubygems.org/api/v1/versions/#{name}.json").to_s
    end
    JSON.parse(versions_json)
  end
end
