class Billing::Stripe::Event < Data.define(:event)
  def self.table_name_prefix = "billing_stripe_event_"

  def self.from(payload:, signature:)
    new ::Stripe::Webhook.construct_event(payload, signature, signing_secret)
  end
  def self.signing_secret = ENV.fetch("STRIPE__SIGNING_SECRET") # TODO: read from ENV during initialization instead.

  def accept?
    event.livemode || Rails.env.local?
  end

  def to_receipt
    Receipt.create_from(event)
  end
end
