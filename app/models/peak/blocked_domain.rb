class Peak::BlockedDomain < ApplicationRecord
  enum :source, %i[manual disposable_email_list].index_by(&:itself)

  FORMAT = /\A[a-z0-9][a-z0-9-]*(\.[a-z0-9][a-z0-9-]*)*\.[a-z]{2,}\z/

  # Hand picked, the disposable-email-domains project ships no allowlist to sync from.
  PROTECTED = %w[
    gmail.com googlemail.com
    outlook.com hotmail.com live.com msn.com
    yahoo.com yahoo.co.uk yahoo.co.jp ymail.com
    icloud.com me.com mac.com
    proton.me protonmail.com pm.me
    aol.com fastmail.com zoho.com mail.com
    qq.com 163.com 126.com sina.com
    yandex.ru yandex.com mail.ru
    gmx.com gmx.de gmx.net web.de t-online.de
    tuta.com tutanota.com
    naver.com daum.net seznam.cz
  ].freeze

  normalizes :name, with: -> { _1.strip.downcase }

  validates_uniqueness_of :name
  validates_length_of :name, maximum: 253
  validates_format_of :name, with: FORMAT
  validates_exclusion_of :name, in: PROTECTED, message: "is a major email provider and can't be blocked"
  validate :name_must_be_registrable

  def self.include?(domain) = exists?(name: parents_of(domain))

  def self.parents_of(domain)
    return [] unless domain.to_s.match?(FORMAT)

    labels = domain.split(".")
    Array.new(labels.size) { labels[_1..].join(".") }
  end

  def self.registrable?(domain) = PublicSuffix.valid?(domain, ignore_private: true)

  private
    def name_must_be_registrable
      return if name.blank? || self.class.registrable?(name)
      errors.add :name, "can't be a public suffix, use a registrable domain"
    end
end
