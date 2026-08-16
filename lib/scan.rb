# - find the repeated name section (but we could have brand new gems in between before new releases to an existing gem causes a name to repeat)
# - compare the line count of the appended gems section to the previous file, if it's shorter now it's compacted

require "httpx"

versions = HTTPX.get("https://gem.coop/versions").body.to_s
scanner = StringScanner.new(versions)
scanner.scan_until "---\n"

names = Set.new
line_count = 0
non_repeating_line_count = nil

until scanner.eos?
  name = scanner.scan_until(/(?= )/)
  non_repeating_line_count ||= names.size unless names.add?(name)

  scanner.skip_until "\n"
  line_count += 1
end

repeating_line_count = line_count - non_repeating_line_count.to_i

# bundle exec ruby lib/scan.rb
# {names: 200969, line_count: 213602, non_repeating_line_count: 195646, repeating_line_count: 17956}
puts(names: names.size, line_count:, non_repeating_line_count:, repeating_line_count:)
