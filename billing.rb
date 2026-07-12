# Encapsulates billing owners that can manage billing across one-to-many namespaces.
# A namespace can only be paid/managed by one billing account.
class Billing::Account < ApplicationRecord
  has_many :ownerships, dependent: :destroy
  has_many :owners, through: :ownerships

  has_many :licenses, dependent: :destroy
  has_many :namespaces, through: :licenses
end

# Equivalent to a Customer in Stripe.
class Billing::Account::Ownership < ApplicationRecord
  belongs_to :account
  belongs_to :owner, class_name: "User"

  t.string :external_id, null: true
end

# Allow multiple licenses per namespace? So if you close one the next active one is still active, e.g. the grandfathered beta namespace licenses are always active?
class Billing::Account::License < ApplicationRecord
  belongs_to :account
  belongs_to :namespace

  # How do we attach our product in Stripe to a specific identifier that we recognize over here?
  t.string :external_id # Stripe::Subscription id
  t.string :product_id # e.g. v1.free
  t.string :status # we'll either have customer.subscription.created|deleted from Stripe

  enum :status, %i[active closed].index_by(&:itself)

  def product
    Billing::Product.fetch(product_id)
  end

  def grant
    namespace.entitlements.upsert_all product.entitlements, update_only: :value
  end

  def revoke
    namespace.entitlements.destroy_by name: product.entitlement_names
  end
end

class Billing::Product
  def entitlement_names = entitlements.map { _1[:name] }
  def entitlements = []

  module V1; end

  class V1::Personal < self
    def entitlements = [
      # Express entitlements solely as integer columns? But simulate a boolean column via 0/1?
      { name: :push_gems, limit: Integer::INFINITY }
    ]
  end

  class V1::Free < self
  end

  @list = subclasses.map(&:new).index_by { _1.name.underscore.tr("/", ".") }
  singleton_class.attr_reader :list
  singleton_class.delegate :fetch, to: :list
  define_singleton_method(:free) { fetch :free }
end

