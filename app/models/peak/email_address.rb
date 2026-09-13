class Peak::EmailAddress < DelegateClass(Mail::Address)
  def self.table_name_prefix = "peak_email_address_"

  class Type < ActiveModel::Type::ImmutableString
    def cast(value) = Peak::EmailAddress.new(value)
  end

  def initialize(address)
    super Mail::Address.new(address)
  end

  def disposable_domain?
    DisposedDomain.include? domain
  end
end
