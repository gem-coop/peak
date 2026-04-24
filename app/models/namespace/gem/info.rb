class Namespace::Gem::Info < ApplicationRecord
  belongs_to :gem
  # TODO: `trimmed` doesn't carry over from the gem.versions association
  # has_many :versions, -> { trimmed.published_order }, through: :gem
  def versions = gem.versions.trimmed.published_order

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
# Table name: namespace_gem_infos
#
#  id         :bigint           not null, primary key
#  checksum   :string           default(""), not null
#  contents   :text             default(""), not null
#  envelope   :string           default(""), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  gem_id     :bigint           not null
#
# Indexes
#
#  index_namespace_gem_infos_on_gem_id  (gem_id)
#
