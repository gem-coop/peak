class Peak::Terms::Acceptance < ApplicationRecord
  self.table_name = "peak_terms_acceptances"

  belongs_to :terms
  belongs_to :user

  scope :pending,  -> { where(accepted: false) }
  scope :accepted, -> { where(accepted: true) }
  def pending? = !accepted?

  def capture(accepted:, time_zone:)
    update! accepted:, time_zone:, captured_at: Time.current, sha: Peak.release.sha unless accepted?
  end

  def local_captured_at
    captured_at.in_time_zone time_zone
  end
end
