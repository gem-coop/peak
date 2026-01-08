class Namespace::Gem::Line < ActiveRecord::AssociatedObject
  def parse(line)
    refs, metadata = line.split("|")
    ref, refs = refs.split(" ", 2)
    version_id = gem.versions.upsert({ref:}, unique_by: [:gem_id, :ref], returning: :id).
        to_a.dig(0, "id")

    if metadata
      Namespace::Gem::Version::Metadata.upsert metadata
        .split(",").to_h { _1.split(":") }.merge(version_id:)
    end

    if refs
      refs.split(":").each do |name, ranges|
        gem = namespace.gems.upsert({name:}, unique_by: [:namespace_id, :name])

        ranges.split("&").each do |ref|
          gem.versions.upsert({ref:}, unique_by: [:gem, :ref])
          version.references.upsert({ref:}, unique_by: [:version, :ref])
        end
      end
    end

    version_id
  end

  private
    delegate :namespace, to: :gem
end
