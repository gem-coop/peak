# The compact-index format is newline-delimited, so interpolated fields must carry no line
# terminators or a crafted value could forge an extra row. `.safe` is the single chokepoint;
# spaces and field delimiters (`, | : &`) stay allowed since they appear in legitimate values.
class Peak::CompactIndex
  UnsafeValue = Class.new(StandardError)
  FORBIDDEN   = /[\r\n\x00]/

  def self.safe(value)
    if value.to_s.match?(FORBIDDEN)
      raise UnsafeValue, "compact-index field contains a forbidden control byte: #{value.inspect}"
    end

    value
  end
end
