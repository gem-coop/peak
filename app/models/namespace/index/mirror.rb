class Namespace::Index::Mirror < ApplicationRecord
  belongs_to :index
  has_object :upstream

  def import
    seen_gems = Set.new

    # use the created_at time and the last line we saw to know when to stop
    lines = upstream.versions.lines
    if lines.first.starts_with?("created_at:")
      created_at = Time.parse(lines.first.split(":", 2)[1])
      if created_at != self.last_created_at
        self.update!(last_line: nil)
      end
      self.update!(last_created_at: created_at)
    else
      self.update!(last_line: nil)
    end

    lines.reverse_each do |line|
      next if line.match(/^created_at:|^---/)
      break if last_line == line

      name, versions, hash = line.split(" ")
      next if seen_gems.include?(name)

      seen_gems.add(name)

      if Sidekiq.server?
        import_line_later(name, versions, hash)
      else
        import_line(name, versions, hash)
      end
    end

    if self.last_line.nil?
      removed_gems = Set.new(index.gems.pluck(:name)) - seen_gems
      index.gems.where(name: removed_gems).destroy_all if removed_gems.any?
    end

    self.update!(last_line: lines.last)
  end
  performs :import

  def import_line(name, versions, hash)
    gem = index.gems.find_by(name:)

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
    yanked = cvs.select { |cv| cv[:published_at].nil? }.map { |cv| cv[:ref] }
    gem.versions.where(ref: yanked).destroy_all if yanked.any?
    cvs.reject! { |cv| cv[:published_at].nil? }

    if cvs.any?
      first_publish = cvs.map { |cv| cv[:published_at] }.min
      gem.update(created_at: first_publish) if first_publish < gem.created_at
    end

    cvs.each { |cv| cv[:gem_id] = gem.id }
    imported_ids = gem.versions.insert_all(cvs, unique_by: %i[gem_id ref])
    gem.versions.where(id: imported_ids).trigger_precompile_later_bulk

    gem.versions.where.not(ref: vset).destroy_all

    gem.info.rebuild if imported_ids.any?
  end
  performs :import_line
end
