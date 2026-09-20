class Namespace::Mirror < ApplicationRecord
  belongs_to :namespace
  validates :url, presence: true

  before_validation do
    self.url << "/" unless url.ends_with?("/")
  end

  def uri
    @uri ||= Addressable::URI.parse(url)
  end

  performs def sync
    gems_to_sync.in_groups_of(1000, false).each do |names|
      # ensure the gems exist
      gem_attrs = names.map { {name: _1, namespace_id:} }
      Namespace::Gem.upsert_all gem_attrs, unique_by: %i[namespace_id name], returning: false

      # queue and import those gem's versions
      Namespace::Gem::Imports.where(namespace_id:, name: names).each do |i|
        i.import_all namespace.stable_index
      end
    end

    # compact?
    # update cooldowns?
  end

  def gems_to_sync
    lines = versions.lines
    lines = lines[last_seen_line..] if last_seen_line_valid?(lines)
    update_last_seen_line!(versions.lines)
    lines.map { _1.split(" ", 2).first }.uniq
  end

  def last_seen_line_valid?(lines)
    last_line = last_seen_line && lines[last_seen_line]
    last_line && last_line.end_with?(last_seen_line_end)
  end

  def update_last_seen_line!(lines)
    last_seen_line = lines.size - 1
    last_seen_line_end = lines[last_seen_line]&.slice(-50..)
    update!(last_seen_line:, last_seen_line_end:)
  end

  def versions
    versions = HTTPX.get(uri.join("versions")).body.to_s
    versions.tap { |v| v.sub!(/\A.*---\n/m, "") } # Trim out metadata
  end
end
