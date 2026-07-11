def gems.oaken_published_at = Time.utc(2026, 1, 20)
def gems.oaken_lines = [
  "0.9.1 |checksum:86c502949e539dd53e40e66664502c7a0bda537eccdfa9ae426f0c90c354ba03,ruby:>= 3.0.0,published_at:#{oaken_published_at.as_json}\n",
  "1.0.0 |checksum:e89249bc4f6cd3ab9b5e3abdc06c377fa772e6bcb3005cc09ff044bb8d3f1dc2,ruby:>= 3.2,published_at:#{oaken_published_at.as_json}\n"
]

def gems.import(name, **)
  create(name:, **).imports.import_all
end

def gems.parse(name, index, *lines)
  create(name, name:).tap do |gem|
    lines.flatten.map { parse_line(gem, index, _1) }
  end
end

def gems.parse_line(gem, index, line)
  refs, metadata = line.split("|")
  ref, refs = refs.split(" ", 2)

  metadata = metadata.split(",").to_h { _1.split(":", 2) }.compact if metadata
  version = context.versions.create(gem:, index:, ref:, line:, **metadata, unique_by: [:gem, :index, :ref])

  ref_ids = context.references.parse_inserts(refs)
  version.reference_ids = ref_ids if ref_ids.any?

  index.append version
end

def references.parse_inserts(refs)
  refs&.split(",").to_a.flat_map do |group|
    name, ranges = group.split(":")

    inserts = ranges.split("&").map do
      operator, ref = it.split(" ")
      {name:, operator:, ref: ref || "0" }
    end

    type.insert_all(inserts, unique_by: [:name, :operator, :ref], returning: :id).rows.map(&:first).flatten
  end
end
