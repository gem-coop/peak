# Only absolute http(s) URLs with a host are safe to render in views.
# Crafted gems can smuggle `javascript:`/`data:` schemes past `gem build`.
class Peak::Gem::Link
  def self.parse(value)
    URI(value.to_s).then.find { _1.is_a?(URI::HTTP) && _1.host.present? }&.to_s if value
  rescue URI::InvalidURIError
    nil
  end
end
