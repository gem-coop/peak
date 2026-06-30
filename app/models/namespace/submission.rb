class Namespace::Submission < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :namespace, foreign_key: :name, primary_key: :name, optional: true

  enum :status, %i[pending reserved approved rejected].index_by(&:itself)
  scope :resolved, -> { not_pending }
  def resolved? = !pending?

  normalizes :name, with: -> { _1.start_with?("@") ? _1 : "@#{_1}" }

  class_attribute :name_pattern, default: /@[a-z0-9-]+/ # For embedding in HTML5 input patterns.
  validates_uniqueness_of :name, conditions: -> { resolved }
  validates_format_of :name, with: /\A#{name_pattern}\z/

  after_create :deliver_welcome_later, :slack_notify_later_if_verified, unless: :resolved?

  performs def process_approved
    ensure_owner_verified!
    raise NamespaceAlreadyExistsError if namespace

    transaction do
      create_namespace!(owners: [owner])
      mailer.approved.deliver_later
    end
  end
  class NamespaceAlreadyExistsError < StandardError; end
  class OwnerEmailUnverifiedError < StandardError; end

  def resolve!(status, at: Time.current)
    ensure_owner_verified! if status.to_s == "approved"
    update! status:, resolved_at: at
  end

  performs def slack_notify
    Slack.notify self, "Namespace #{name} requested"
  end

  private
    def deliver_welcome_later
      mailer.welcome.deliver_later
    end

    def slack_notify_later_if_verified
      slack_notify_later if owner.verified?
    end

    def ensure_owner_verified!
      return if owner.verified?

      raise OwnerEmailUnverifiedError, "Owner must verify email address before approval"
    end
end
