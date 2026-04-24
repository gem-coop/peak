class Namespace::Index::Mirror < ApplicationRecord
  belongs_to :index
  has_object :upstream

  def import
    # prevent running two imports at once
    return if last_processed_at < last_started_at
    # prevent queueing multiple imports at once
    return unless Sidekiq::Queue.new("mirror").size.zero?

    self.update!(last_started_at: Time.now)
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

      name, versions, _ = line.split(" ")
      # if we already updated the gem with this name, we're good
      next if seen_gems.include?(name)

      seen_gems.add(name)
      import_line_later(name, versions)
    end

    # if we are processing the whole file, delete any (yanked) gems we didn't see
    if self.last_line.nil?
      removed_gems = Set.new(index.gems.pluck(:name)) - seen_gems
      index.gems.where(name: removed_gems).destroy_all if removed_gems.any?
    end

    self.update!(last_line: lines.last, last_processed_at: Time.now)
  end
  performs :import

  def import_line(name, versions)
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
      refs, metadata = info_line.chomp.split("|")
      ref, refs = refs.split(" ", 2)
      metadata = metadata.split(",").to_h { _1.split(":", 2) }.compact if metadata

      vset.add(ref)
      {ref:, created_by_id:, refs:}.merge(metadata)
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

    version_refs = gem.versions.pluck(:ref)

    imported_ids = cvs.map do |cv|
      ref = cv[:ref]
      next if version_refs.include?(ref)

      reference_ids = create_refs(cv[:refs])
      cv.delete(:refs)
      version = gem.versions.create(**cv, reference_ids:)
      gem.process_version version
      version.save!

      # version.trigger_precompile_later

      version.id
    end.compact

    gem.versions.where.not(ref: vset).destroy_all

    if imported_ids.any?
      gem.info.rebuild
      gem.cooldown_infos.find_each(&:rebuild)
    end
  end
  performs :import_line, queue_as: :mirror

  def create_refs(refs)
    refs&.split(",").to_a.flat_map do |group|
      name, ranges = group.split(":")

      inserts = ranges.split("&").map do
        operator, ref = it.split(" ")
        {name:, operator:, ref: ref || "0" }
      end

      Namespace::Gem::Version::Reference.upsert_all(inserts)
    end
  end
end



# == Schema Information
#
# Table name: namespace_index_mirrors
#
#  id                :bigint           not null, primary key
#  last_created_at   :datetime
#  last_line         :string
#  last_processed_at :datetime         default(1970-01-01 00:00:00.000000000 UTC +00:00), not null
#  last_started_at   :datetime         default(1970-01-01 00:00:00.000000000 UTC +00:00), not null
#  upstream_url      :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  index_id          :bigint           not null
#
# Indexes
#
#  index_namespace_index_mirrors_on_index_id  (index_id)
#
# Foreign Keys
#
#  fk_rails_...  (index_id => namespace_indexes.id)
#
