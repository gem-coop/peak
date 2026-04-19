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
