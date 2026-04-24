class Namespace::Gem::Version::Linking < ApplicationRecord
  belongs_to :version
  belongs_to :link
end

# == Schema Information
#
# Table name: namespace_gem_version_linkings
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  link_id    :bigint           not null
#  version_id :bigint           not null
#
# Indexes
#
#  index_namespace_gem_version_linking_uniqueness      (version_id,link_id) UNIQUE
#  index_namespace_gem_version_linkings_on_link_id     (link_id)
#  index_namespace_gem_version_linkings_on_version_id  (version_id)
#
