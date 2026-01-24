class Namespace::Gem::Info < ApplicationRecord
  belongs_to :gem
  # TODO: `trimmed` doesn't carry over from the gem.versions association
  # has_many :versions, -> { trimmed }, through: :gem
  def versions = gem.versions.trimmed

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
