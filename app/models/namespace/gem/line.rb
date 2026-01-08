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
      refs.split(",").each do |constraints|
        name, ranges = constraints.split(":")
        gem_id = namespace.gems.upsert({name:}, unique_by: [:namespace_id, :name], update_only: :name, returning: :id).
            to_a.dig(0, "id")

        ranges.split("&").each do |ref|
          operator, ref = ref.split(" ")
          ref = "0" if ref.nil?

          linked_id = Namespace::Gem::Version.upsert({gem_id:, ref:}, unique_by: [:gem_id, :ref], update_only: :ref, returning: :id).
            to_a.dig(0, "id")
          Namespace::Gem::Version::Reference.upsert({source_id: version_id, linked_id:, operator:}, unique_by: [:source_id, :linked_id, :operator])
        end
      end
    end

    version_id
  end

  private
    delegate :namespace, to: :gem
end
