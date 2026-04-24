class Namespace::Index::Cooldown < ApplicationRecord
  belongs_to :index, class_name: "Namespace::Index"
  default_scope { select(*column_names.without("versions_contents")) }

  has_many :gems, ->(cooldown) { where("namespace_gems.created_at <= ?", cooldown.days_delayed.days.ago) }, through: :index
  has_many :versions, ->(cooldown) { where("published_at <= ?", cooldown.days_delayed.days.ago) }, through: :gems, class_name: "Namespace::Gem::Version"
  has_many :infos, -> { where(cooldown_id: id) }, through: :gems, class_name: "Namespace::Gem::CooldownInfo", dependent: :destroy

  attribute :last_compacted_at, default: -> { Time.current }

  def append(envelope)
    versions_contents << envelope
    save!
  end

  def versions_contents
    read_unloaded_attribute __method__
  end

  performs def compact
    update! versions_contents: contents, last_compacted_at: Time.current
  end

  def rebuild_infos(period: 1.day)
    gem_ids = versions.where("published_at >= ?", (days_delayed.days + period + 12.hours).ago).pluck(:gem_id).uniq
    gems.where(id: gem_ids).find_each do |gem|
      gem.cooldown_infos.find_or_create_by!(cooldown: self).rebuild
    end
    compact_later
  end

  def public_cache?
    index.external_access? || index.dev_access?
  end

  private

    def contents
      contents = frontmatter.clone
      gems.find_each do |gem|
        contents << gem.cooldown_infos.find_or_create_by!(cooldown: self).rebuild.envelope
      end
      contents
    end

    def frontmatter = "created_at: #{Time.now.utc.iso8601}\n---\n"
end

# == Schema Information
#
# Table name: namespace_index_cooldowns
#
#  id                :bigint           not null, primary key
#  days_delayed      :integer          default(2), not null
#  last_compacted_at :datetime         not null
#  versions_contents :text             default("---\n"), not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  index_id          :bigint           not null
#
# Indexes
#
#  index_namespace_index_cooldowns_on_index_id  (index_id)
#
# Foreign Keys
#
#  fk_rails_...  (index_id => namespace_indexes.id)
#
