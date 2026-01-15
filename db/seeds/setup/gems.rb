def gems.parse(name, *lines)
  gem = create(name, name:, unique_by: [:namespace, :name])
  lines.map { parse_line gem, _1 }
end

def gems.parse_line(gem, line)
  refs, metadata = line.split("|")
  ref, refs = refs.split(" ", 2)

  version = context.versions.create(gem:, ref:, unique_by: [:gem, :ref])
  version.create_metadata metadata.split(",").to_h { _1.split(":") } if metadata

  refs&.split(",").to_a.each do |constraints|
    name, ranges = constraints.split(":")
    gem_id = create(name:, unique_by: [:namespace, :name]).id

    ranges.split("&").each do |ref|
      operator, ref = ref.split(" ")
      ref = "0" if ref.nil?

      linked_id = context.versions.create(gem:, ref:, unique_by: [:gem, :ref]).id
      version.references.insert({linked_id:, operator:}, unique_by: [:source_id, :linked_id, :operator])
    end
  end
end
