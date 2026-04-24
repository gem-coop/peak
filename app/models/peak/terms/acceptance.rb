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

# == Schema Information
#
# Table name: peak_terms_acceptances
#
#  id          :bigint           not null, primary key
#  accepted    :boolean          default(FALSE), not null
#  captured_at :datetime         not null
#  sha         :string           not null
#  time_zone   :string           not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  terms_id    :bigint           not null
#  user_id     :bigint           not null
#
# Indexes
#
#  index_peak_terms_acceptances_on_terms_id  (terms_id)
#  index_peak_terms_acceptances_on_user_id   (user_id)
#
