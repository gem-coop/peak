class Namespace::Mirror < ApplicationRecord
  BATCH_SIZE = 1000

  belongs_to :namespace

  scope :enabled, -> { where(enabled: true) }

  validates :url, presence: true
  normalizes :url, with: -> { _1.chomp("/") << "/" }

  def uri
    @uri ||= Addressable::URI.parse(url)
  end

  def queue_cycle = %w[import_1 import_2 import_3 import_4].cycle

  performs def sync(force_all: false)
    update!(last_seen_line_no: nil, last_seen_line_end: nil) if force_all

    queues = queue_cycle
    gems_to_sync { enqueue_batch _1, queue: queues.next }

    # compact?
    # update cooldowns?
  end

  def enqueue_batch(names, queue: queue_cycle.next)
    gem_attrs = names.map { {name: _1, namespace_id:} }
    Namespace::Gem.upsert_all gem_attrs, unique_by: %i[namespace_id name], returning: false
    ActiveJob.perform_all_later gem_attrs.map { GemImportJob.new(**_1).set(queue:) }
  end

  def gems_to_sync
    lines = versions.lines(chomp: true).each_with_index.to_a
    Rails.logger.debug { "[mirror] #{url} versions contains #{lines.count} lines" }
    lines = lines[(last_seen_line_no + 1)..] if last_seen_line_valid?(lines)
    Rails.logger.debug { "[mirror] Resuming after line #{last_seen_line_no.inspect}: #{lines.count} lines left" }

    lines.each_slice(BATCH_SIZE) do |batch|
      yield batch.map { _1.first.split(" ", 2).first }.uniq
      update_last_seen_line!(*batch.last)
    end
  end

  # Ensure our line number matches the content of the line as well
  def last_seen_line_valid?(lines)
    last_seen_line_no && lines[last_seen_line_no]&.first&.end_with?(last_seen_line_end)
  end

  def update_last_seen_line!(line, line_no)
    Rails.logger.debug { "[mirror] Updating last seen line to #{line_no}" }
    update! last_seen_line_no: line_no, last_seen_line_end: line.last(50)
  end

  def versions
    versions = HTTPX.get(uri.join("versions")).body.to_s
    versions.tap { |v| v.sub!(/\A.*---\n+/m, "") } # Trim out metadata
  end
  def names = versions.scan(/^.*?(?= )/).uniq
end
