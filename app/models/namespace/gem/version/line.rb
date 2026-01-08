class Namespace::Gem::Version::Line < ActiveRecord::AssociatedObject
  def to_s
    "#{version.ref} #{reference_parts.join(",")}|#{version.metadata.line}"
  end

  private
    def reference_parts
      version.references.line_parts
    end
end
