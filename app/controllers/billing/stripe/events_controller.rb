# Adapted from Pay::Webhooks::StripeController
class Billing::Stripe::EventsController < ActionController::API
  rescue_from ::Stripe::SignatureVerificationError, with: -> { head :bad_request }

  def create
    event = Billing::Stripe::Event.from(payload:, signature:)
    event.to_receipt.process_later if event.accept?
  end

  private
    def payload   = request.body.read
    def signature = request.get_header("HTTP_STRIPE_SIGNATURE")
end
