require "test_helper"

class Peak::Terms::AcceptanceTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
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
