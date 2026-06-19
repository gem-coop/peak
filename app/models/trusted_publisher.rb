class TrustedPublisher < ApplicationRecord
  belongs_to :namespace
  belongs_to :gem, class_name: "Namespace::Gem", optional: true
  belongs_to :provider, class_name: "OIDC::Provider"

  has_many :push_keys, dependent: :destroy

  validates :gem_name, presence: true

  scope :pending, -> { where(gem_id: nil) }

  def pending? = gem_id.nil?
  def target_index = gem&.index || namespace.default_index

  def link_gem!(gem)
    update!(gem:) if pending? && gem.name == gem_name
  end

  # Subclasses implement #matches?(claims) for their provider's claim shape.
  def matches?(_claims) = raise NotImplementedError
end
