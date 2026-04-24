class Namespace::Access < ApplicationRecord
  belongs_to :namespace
  belongs_to :user

  enum :role, %i[plain owner].index_by(&:itself)
end

# == Schema Information
#
# Table name: namespace_accesses
#
#  id           :bigint           not null, primary key
#  role         :string           default("plain"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  namespace_id :bigint           not null
#  user_id      :bigint           not null
#
# Indexes
#
#  index_namespace_accesses_on_namespace_id  (namespace_id)
#  index_namespace_accesses_on_user_id       (user_id)
#
