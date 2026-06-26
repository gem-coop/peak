# Only absolute http(s) URLs with a host are safe to render as anchors; a crafted gem can smuggle
# `javascript:`/`data:` schemes past gem build.
class Peak::Gem::Link
  ALLOWED_SCHEMES = %w[http https].freeze

  def self.safe?(value)
    uri = URI.parse(value.to_s)
    ALLOWED_SCHEMES.include?(uri.scheme&.downcase) && uri.host.present?
  rescue URI::InvalidURIError
    false
  end
end
