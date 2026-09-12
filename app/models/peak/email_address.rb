require "mail"

class Peak::EmailAddress < DelegateClass(Mail::Address)
  class Type < ActiveModel::Type::Value
    def cast(value) = value.is_a?(Peak::EmailAddress) ? value : Peak::EmailAddress.new(value)
  end

  def initialize(address)
    @address = address.to_s
    super Mail::Address.new(@address)
  rescue Mail::Field::IncompleteParseError
    super Mail::Address.new
  end

  def domain = super&.downcase

  def blocked_domain? = Peak::BlockedDomain.include?(domain)

  def to_s = @address
end
