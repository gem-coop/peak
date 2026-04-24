class Namespace::Gem::CooldownInfo < ApplicationRecord
  belongs_to :gem, class_name: "Namespace::Gem"
  belongs_to :cooldown, class_name: "Namespace::Index::Cooldown"

  def versions
    gem.versions.where("published_at <= ?", cooldown.days_delayed.days.ago).trimmed.published_order
  end

  def rebuild
    io = DigestedIO.new.consume(batched_versions, &:line)

    self.contents = io.string
    self.checksum = io.hexdigest
    self.envelope = envelope_from(versions.pluck(:ref))
    save!
    self
  end

  def envelope_from(refs)
    "#{gem.name} #{Array(refs).join(",")} #{checksum}\n"
  end

  private
    def batched_versions
      versions.includes(:references).find_each(batch_size: 200)
    end
end

# == Schema Information
#
# Table name: namespace_gem_cooldown_infos
#
#  id          :bigint           not null, primary key
#  checksum    :string           default(""), not null
#  contents    :text             default(""), not null
#  envelope    :string           default(""), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  cooldown_id :bigint           not null
#  gem_id      :bigint           not null
#
# Indexes
#
#  index_namespace_gem_cooldown_infos_on_cooldown_id  (cooldown_id)
#  index_namespace_gem_cooldown_infos_on_gem_id       (gem_id)
#
# Foreign Keys
#
#  fk_rails_...  (cooldown_id => namespace_index_cooldowns.id)
#  fk_rails_...  (gem_id => namespace_gems.id)
#
