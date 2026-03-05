class CooldownVersion < ApplicationRecord
  default_scope -> { where(yanked_at: nil) }
  scope :cooled, -> { where("published_at < ?", 48.hours.ago).order(:published_at) }

  IMPORT_QUEUES = %w[import_1 import_2 import_3 import_4].freeze

  def self.import
    version_jobs.tap { |jobs| ActiveJob.perform_all_later(jobs) }.count
  end

  def self.version_jobs(force_all: false)
    versions = Server.versions
    versions_byte = 0

    # make sure we won't look past the end of the current file, even if these jobs aren't all done
    CooldownVersion.where("versions_byte > ?", Server.versions.size).update_all(versions_byte: nil)

    unless force_all
      cv = CooldownVersion.where.not(versions_byte: nil).order(:versions_byte).last
      cv_line = cv && Server.versions_until(cv.versions_byte).lines.last
      # jump to our last known version if it's still good
      if cv_line && cv_line.starts_with?(cv.name) && cv_line.include?(cv.version) && cv_line.ends_with?("\n")
        versions_byte = cv.versions_byte
      end
    end

    # Upstash Redis dies if the default queue value is >10MB,
    # so we are trying to guarantee that we never have more
    # than about 125,000 jobs in a single queue, here.
    queue_name = IMPORT_QUEUES.cycle

    versions[versions_byte..].lines.map do |version_line|
      versions_byte += version_line.size
      next if version_line.match(/^created_at:|^---/)
      CooldownVersionLineImportJob.new(versions_byte, version_line).tap do |job|
        job.queue_name = queue_name.next
      end
    end.compact
  end

  def self.import_name(name)
    version_jobs(force_all: true).find { |j| j.arguments[1].starts_with?("#{name} ") }.perform_now
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

    return if cvs.empty?

    # Try to get published_at from our own database before we make an API call
    db_versions = self.where(name:).where.not(published_at: nil).pluck(:version, :published_at).to_h
    cvs.each { |cv| cv[:published_at] = db_versions[cv[:version]] }

    # If that didn't work, get the times from an API call
    if cvs.any? { |cv| cv[:published_at].nil? }
      versions = Server.versions_json(name)
      cvs.each do |cv|
        v = versions.find do |v|
          full_v = [v["number"]]
          full_v << v["platform"] unless v["platform"] == "ruby"
          cv[:version] == full_v.join("-")
        end

        v && cv[:published_at] = v["created_at"]
      end
    end

    # Anything that still doesn't have a published_at was yanked We can't get
    # the exact yanked_at from any API call, since yanked gems are not included
    # in API responses. This should be good enough for our purposes, since
    # yanked gems will not be included in future query results.
    cvs.select { |cv| cv[:published_at].nil? }.each do |cv|
      cv[:published_at] = 1.hour.ago
      cv[:yanked_at] = Time.now
    end

    CooldownVersion.upsert_all(cvs, unique_by: %i[name version])
  end

  module Server
    class GemYankedError < RuntimeError; end

    mattr_reader :memory_store, default:
      ActiveSupport::Cache.lookup_store(:memory_store, compress: true)

    def self.cached_get(path, expires_in:, store: self.memory_store)
      store.fetch(path, expires_in:) do
        HTTPX.plugin(:brotli).get("https://#{path}").tap do |res|
          if res.is_a?(HTTPX::ErrorResponse) || 405 <= res.status
            raise "Request to #{res.uri} failed, got: #{res.inspect}"
          elsif path.ends_with?(".json") && res.status == 404
            raise GemYankedError, path
          end
        end.to_s
      end
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
    rescue GemYankedError
      {}
    end
  end
end
