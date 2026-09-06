class Namespace::Submission < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :namespace, foreign_key: :name, primary_key: :name, optional: true

  enum :status, %i[pending reserved approved rejected].index_by(&:itself)
  scope :resolved, -> { not_pending }
  def resolved? = !pending?

  normalizes :name, with: -> { _1.start_with?("@") ? _1 : "@#{_1}" }

  class_attribute :name_pattern, default: /@[a-z0-9-]+/ # For embedding in HTML5 input patterns.
  validates_uniqueness_of :name
  validates_format_of :name, with: /\A#{name_pattern}\z/

  before_create :reject_existing_namespace_submission, if: :pending?
  after_create :deliver_welcome_later, :slack_notify_later, unless: :resolved?

  performs def process_approved
    raise NamespaceAlreadyExistsError if namespace

    transaction do
      create_namespace!(owners: [owner])
      mailer.approved.deliver_later
    end
  end
  class NamespaceAlreadyExistsError < StandardError; end

  def resolve!(status, at: Time.current)
    update! status:, resolved_at: at
  end

  performs def slack_notify
    Slack.notify self, "Namespace #{name} requested"
  end

  private
    def reject_existing_namespace_submission
      assign status: :rejected, resolved_at: Time.current if pending? && namespace
    end

    def deliver_welcome_later
      mailer.welcome.deliver_later
    end
end
