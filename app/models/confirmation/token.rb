class Confirmation::Token < Data.define(:store)
  singleton_class.attr_writer :nonce
  def self.nonce = @nonce || SecureRandom.hex

  def token = read&.first
  def nonce = read&.last
  delegate :read, :delete, to: :store

  def write(token)
    store.write [token, self.class.nonce] if token.present?
  end

  def nonce?(value)
    nonce.present? && ActiveSupport::SecurityUtils.secure_compare(nonce, value.to_s)
  end
end
