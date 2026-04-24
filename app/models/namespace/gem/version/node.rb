class Namespace::Gem::Version::Node < ApplicationRecord
  belongs_to :version
  belongs_to :reference
end

# == Schema Information
#
# Table name: namespace_gem_version_nodes
#
#  id           :bigint           not null, primary key
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  reference_id :bigint           not null
#  version_id   :bigint           not null
#
# Indexes
#
#  index_namespace_gem_version_nodes_on_reference_id  (reference_id)
#  index_namespace_gem_version_nodes_on_version_id    (version_id)
#  namespace_gem_version_nodes_uniqueness             (version_id,reference_id) UNIQUE
#
