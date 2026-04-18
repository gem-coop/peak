class Namespace::Mirror < ApplicationRecord
  belongs_to :namespace
  has_object :upstream

  def import
    upstream.versions.lines.each do |line|
      next if line.match(/^created_at:|^---/)
      if Sidekiq.server?
        import_line_later(line)
      else
        import_line(line)
      end
    end
  end
  performs :import

  def import_line(line)
    name, vset, _ = line.split(" ", 3)
    vset = Set.new(vset.split(","))

    # Handle lines that are just yanks
    if vset.size == 1 && vset.first.starts_with?("-")
      gem = namespace.external_index.gems.find_or_create_by!(name:)
      return gem.versions.where(ref: vset.first[1..]).destroy_all
    end

    created_by_id = Peak.system_user.id
    info = upstream.info(name)
    cvs = info.lines.map do |info_line|
      next if info_line.match(/^created_at:|^---/)
      ref, _ = info_line.split(" ", 2)
      next unless vset.include?(ref)
      {ref:, created_by_id:}
    end.compact

    return if cvs.empty?

    # Try to get info from our own database before we make an API call
    gem = namespace.external_index.gems.find_or_create_by!(name:)
    db_versions = gem.versions.pluck(:ref)
    cvs.delete_if { |cv| db_versions.include?(cv[:ref]) }

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
          cv[:summary] = v["summary"]
        end
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

    cvs.each { |cv| cv[:gem_id] = gem.id }
    gem.versions.insert_all(cvs, unique_by: %i[gem_id ref])
    gem.info.rebuild
  end
  performs :import_line
end
