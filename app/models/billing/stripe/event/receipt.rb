class Billing::Stripe::Event::Receipt < ApplicationRecord
  # belongs_to :account, class_name: "Billing::Account", optional: true
  enum :status, %i[pending processing errored stockpiled processed].index_by(&:itself)

  self.inheritance_column = nil # Disable STI since we're repurposing its `type` column.

  def self.create_from(event)
    create!(type: event.type, data: event)
  end

  performs def process
    associate_account
    stockpile || dispatch if reentrant?
  rescue
    errored!
    raise
  end
  def reentrant? = pending? || errored? || stockpiled?

  def event
    @event ||= ::Stripe::Event.construct_from(data)
  end

  Abstract = Data.define(:event, :receipt) do
    delegate :context, :data, :id, to: :event
    delegate :object,  to: :data
    delegate :account, to: :receipt
  end

  class Customer < Abstract
    def created = nil # account.update!(external_id: id)
  end

  class Customer::Subscription < Abstract
    def created = nil # account.licenses.create!(namespace_id: context.namespace_id, product_id: object.plan.product, price_id: object.plan.id)
    def deleted = nil # account.licenses.find_by!(product_id: context.product)
    def updated = nil
  end

  private
    def associate_account
      self.account ||= Billing::Account.find_signed! event.context[:account_id]
    end

    def stockpile
      stockpiled! unless processable?
    end
    def processable? = processor&.respond_to?(dispatch_name)

    def dispatch
      processing!
      processor.public_send(dispatch_name)
      processed!
    end
    def processor = @processor ||= const_get?(processor_ref)&.new(event, self)

    def processor_ref = @processor_ref || split_type.first
    def dispatch_name = @dispatch_name || split_type.last
    def split_type
      *ref, dispatch_name = type.split(".")
      @processor_ref, @dispatch_name = ref.join("/").camelize, dispatch_name
    end
end
