class CooldownVersion < ApplicationRecord
  def self.import(import_async = false)
    versions = Rails.cache.fetch("gem.coop/versions", expires_in: 1.hour) do
      HTTPX.plugin(:brotli).get("https://gem.coop/versions").to_s
    end

    versions_byte = 0

    cv = CooldownVersion.order(:created_at).last
    cv_line = cv && versions[...cv.versions_byte]&.lines&.last
    if cv_line && cv_line.starts_with?(cv.name) && cv_line.include?(cv.version)
      from_scratch = false
      # jump to last known version
      versions_byte = cv.versions_byte
      # if we already finished the whole file, great! we're done
      return if versions.length <= versions_byte
    else
      # our saved numbers don't line up with the file we pulled, start over
      from_scratch = true
    end

    cv_jobs = versions[versions_byte..].lines.map do |version_line|
      versions_byte += version_line.size
      next if version_line.match(/^created_at:|^---/)
      CooldownVersionLineImportJob.new(versions_byte, version_line, from_scratch)
    end.compact

    if import_async
      ActiveJob.perform_all_later(cv_jobs)
    else
      cv_jobs.each(&:perform_now)
    end
  end

  def self.import_line(versions_byte, version_line, from_scratch = false)
    name, vset, _ = version_line.split(" ", 3)
    vset = Set.new(vset.split(","))

    info_byte = 0
    unless from_scratch
      info_byte = CooldownVersion.where(name: name).order(:published_at).pick(:info_byte) || 0
    end
    info = Rails.cache.fetch("gem.coop/info/#{name}", expires_in: 1.hour) do
      HTTPX.plugin(:brotli).get("https://gem.coop/info/#{name}").to_s
    end

    cvs = info[info_byte..].lines.map do |info_line|
      info_byte += info_line.size
      next if info_line.starts_with?("---")
      version, _ = info_line.split(" ", 2)
      next unless vset.include?(version)
      {name:, version:, versions_byte:, info_byte:}
    end.compact

    CooldownVersion.upsert_all(cvs, unique_by: %i[name version]) unless cvs.empty?
  end

  # We need to backfill published_at, but only for the last 48 hours.
  def self.backfill_published_at
    return if CooldownVersion.where(published_at: nil).empty?

    versions = Rails.cache.fetch("gem.coop/versions", expires_in: 1.hour) do
      HTTPX.plugin(:brotli).get("https://gem.coop/versions").to_s
    end

    # If we don't have gems created in the last 48 hours, iterate from the (newest) end of versions,
    # pulling the JSON with published_at dates, adding those dates to the database, and iterating
    # until we find a gem whose most recent version is older than 48 hours. That means we're done!
    versions.lines.reverse_each do |line|
      next if line.match(/^created_at:|^---/)

      name, _ = line.split(" ", 2)

      api_versions = HTTPX.plugin(:brotli).get("https://rubygems.org/api/v1/versions/#{name}.json").json

      version_dates = api_versions.map do |vj|
        {name: name, version: vj["number"], published_at: vj["created_at"]}
      end

      newest_date = Time.parse(version_dates.first[:published_at])
      break if newest_date < 48.hours.ago

      CooldownVersion.upsert_all(version_dates, unique_by: %i[name version])
    end

    CooldownVersion.where(published_at: nil).update_all(published_at: 49.hours.ago)
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
end
