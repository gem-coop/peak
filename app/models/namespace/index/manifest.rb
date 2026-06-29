class Namespace::Index::Manifest < ApplicationRecord
  belongs_to :author, polymorphic: true, touch: true
  delegate :versions, to: :author

  # TODO: Look into why Active Job execution can't find Manifest, despite supposedly deferring jobs to after transaction commit now.
  after_create_commit :compact_later

  performs def append(versions)
    self.contents <<= Array(versions).map { _1.envelope ref_stamp: _1.ref }.join
    save!
  end

  performs def compact
    update! compacted_at: compacted_at = Time.current,
      contents: "#{compacted_at.iso8601}\n---\n#{computed_contents}"
  end

  private
    def computed_contents
      # versions.distinct_on_gem_name.latest_first.as_byline.inject(+"") { _1 << _2.envelope }
      lines = contents.sub(/\A.*\n---\n/, "").lines

      appenders = {}
      previously_compacted = false

      lines.reverse.map! do |line|
        previously_compacted = true if line.include?(",")

        name = line.byteslice 0, line.index(" ")

        if previously_compacted
          if append = appenders.delete(name)
            line.bytesplice line.rindex(" ").., append
          else
            line
          end
        else
          if appenders[name]
            version = line.byteslice name.size.succ...line.rindex(" ")
            appenders[name].prepend(",").prepend(version)
          else
            appenders.store name, line.byteslice(name.size.succ..)
          end

          ""
        end
      end

      if previously_compacted
        lines.reverse!
      else
        puts appenders
        lines = appenders.keys.sort.map { |name| "#{name} #{appenders[name]}" }
      end

      lines.join
    end
end
