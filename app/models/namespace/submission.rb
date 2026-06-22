class Namespace::Submission < ApplicationRecord
  belongs_to :owner, class_name: "User"
  belongs_to :namespace, foreign_key: :name, primary_key: :name, optional: true

  belongs_to :adjudicated_by, class_name: "User", optional: true

  enum :status, %i[pending reserved approved rejected].index_by(&:itself)
  scope :adjudicated, -> { not_pending }
  def adjudicated? = !pending?

  def to_param = name
  normalizes :name, with: -> { _1.start_with?("@") ? _1 : "@#{_1}" }

  class_attribute :name_pattern, default: /@[a-z0-9-]+/ # For embedding in HTML5 input patterns.
  validates_uniqueness_of :name, conditions: -> { adjudicated }
  validates_format_of :name, with: /\A#{name_pattern}\z/

  after_create :slack_notify_later, unless: :adjudicated?

  performs def process_approved
    raise NamespaceAlreadyExistsError if namespace

    transaction do
      namespace = create_namespace
      namespace.accesses.owner.create! user: owner
      namespace.mailer.approved.deliver_now # TODO: Move mailer to Submission
    end
  end
  class NamespaceAlreadyExistsError < StandardError; end

  def adjudicate!(status, by:, at: Time.current)
    update! status:, adjudicated_by: by, adjudicated_at: at
  end

  performs def slack_notify
    Slack.notify self, "Namespace #{name} requested"
  end
end
