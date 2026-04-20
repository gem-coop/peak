class Namespace::Index::Mirror < ApplicationRecord
  belongs_to :index
  has_object :upstream

  def import
    removed_gems = Set.new(index.gems.pluck(:name))

    upstream.versions.lines.reverse_each do |line|
      next if line.match(/^created_at:|^---/)
      name, versions, hash = line.split(" ")
      removed_gems.delete(name)

      if Sidekiq.server?
        import_line_later(name, versions, hash)
      else
        import_line(name, versions, hash)
      end
    end

    index.gems.where(name: removed_gems).destroy_all if removed_gems.any?
  end
  performs :import

  def import_line(name, versions, hash)
    gem = index.gems.find_by(name:)
    return if gem && gem.info.mirror_checksum == hash

    vset = Set.new(versions.split(","))

    # Handle lines that are just yanks
    if vset.size == 1 && vset.first.starts_with?("-")
      gem = index.gems.find_or_create_by!(name:)
      return gem.versions.where(ref: vset.first[1..]).destroy_all
    end

    created_by_id = Peak.system_user.id
    info = upstream.info(name)
    cvs = info.lines.map do |info_line|
      next if info_line.match(/^created_at:|^---/)
      ref, _ = info_line.split(" ", 2)
      vset.add(ref)
      {ref:, created_by_id:}
    end.compact

    return if cvs.empty?

    # Try to get info from our own database before we make an API call
    gem = index.gems.find_or_create_by(name:)
    if gem
      db_versions = gem.versions.pluck(:ref)
      cvs.delete_if { |cv| db_versions.include?(cv[:ref]) }
    end

    # If that didn't work, get the times from an API call
    if cvs.any? { |cv| cv[:published_at].nil? }
      versions = upstream.versions_json(name)
      cvs.each do |cv|
        v = versions.find do |v|
          full_v = [v["number"]]
          full_v << v["platform"] unless v["platform"] == "ruby"
          cv[:ref] == full_v.join("-")
        end

        if v
          cv[:platform_id] = Peak::Platform.ids_from(v["platform"]).first
          cv[:published_at] = Time.parse(v["created_at"])
          cv[:summary] = v["summary"] || ""
        end
      end
    end

    # Anything that still doesn't have a published_at was yanked
    # We can't get the exact yanked_at from any API call, since yanked gems are
    # not included in API responses. This should be good enough for our
    # purposes, since yanked gems will not be included in future query results.
    cvs.select { |cv| cv[:published_at].nil? }.each do |cv|
      cv[:published_at] = 1.hour.ago
      cv[:yanked_at] = Time.now
    end

    if cvs.any?
      first_publish = cvs.map { |cv| cv[:published_at] }.min
      gem.update(created_at: first_publish) if first_publish < gem.created_at
    end

    cvs.each { |cv| cv[:gem_id] = gem.id }
    imported_ids = gem.versions.insert_all(cvs, unique_by: %i[gem_id ref])
    gem.versions.where(id: imported_ids).trigger_precompile_later_bulk

    gem.versions.where.not(ref: vset).destroy_all
    gem.info.rebuild(mirror_checksum: hash)
  end
  performs :import_line
end
