class TrustedPublisher::PushKey < ApplicationRecord
  self.table_name = "trusted_publisher_push_keys"

  include ExpiringToken

  PREFIX = "gemcoop_tp_"
  TTL = 30.minutes
  SCOPES = %w[push_rubygem].freeze

  belongs_to :trusted_publisher

  # The plaintext token is only ever available on the in-memory record that
  # minted it; the database stores its SHA-256 digest so a DB read leak can't
  # yield usable push credentials.
  attr_reader :token

  attribute :expires_at, default: -> { TTL.from_now }
  before_validation :generate_token, on: :create
  validates :token_digest, presence: true

  delegate :gem_name, :target_index, :namespace, to: :trusted_publisher

  def self.digest(token) = Digest::SHA256.hexdigest(token)

  def name = "trusted-publisher:#{gem_name}"
  def scopes = SCOPES

  private
    def generate_token
      @token ||= "#{PREFIX}#{SecureRandom.urlsafe_base64(32)}"
      self.token_digest ||= self.class.digest(@token)
    end
end
