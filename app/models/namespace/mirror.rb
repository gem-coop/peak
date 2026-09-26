class Namespace::Mirror < ApplicationRecord
  belongs_to :namespace

  scope :enabled, -> { where(enabled: true) }

  validates :url, presence: true

  before_validation do
    self.url = "#{url}/" if url.present? && !url.ends_with?("/")
  end

  def uri
    @uri ||= Addressable::URI.parse(url)
  end

  performs def sync(force_all: false)
    update!(last_seen_line_no: nil, last_seen_line_end: nil) if force_all

    gems_to_sync do |names|
      gem_attrs = names.map { {name: _1, namespace_id:} }
      Namespace::Gem.upsert_all gem_attrs, unique_by: %i[namespace_id name], returning: false
      ActiveJob.perform_all_later gem_attrs.map { Namespace::Mirror::GemImportJob.new(**_1) }
    end

    # compact?
    # update cooldowns?
  end

  def gems_to_sync
    lines = versions.lines(chomp: true)
    Rails.logger.debug { "[mirror] #{url} versions contains #{lines.count} lines" }
    lines = lines[(last_seen_line_no + 1)..] if last_seen_line_valid?(lines)
    Rails.logger.debug { "[mirror] Resuming after line #{last_seen_line_no.inspect}: #{lines.count} lines left" }

    numbered = lines.each_with_index.to_a
    numbered.each_slice(1000) do |batch|
      yield batch.map { _1.first.split(" ", 2).first }.uniq
      update_last_seen_line!(*batch.last)
    end
  end

  # Ensure our line number matches the content of the line as well
  def last_seen_line_valid?(lines)
    last_seen_line_no && lines[last_seen_line_no]&.end_with?(last_seen_line_end)
  end

  def update_last_seen_line!(line, line_no)
    Rails.logger.debug { "[mirror] Updating last seen line to #{line_no}" }
    update! last_seen_line_no: line_no, last_seen_line_end: line.last(50)
  end

  def versions
    versions = HTTPX.get(uri.join("versions")).body.to_s
    versions.tap { |v| v.sub!(/\A.*---\n+/m, "") } # Trim out metadata
  end
end
