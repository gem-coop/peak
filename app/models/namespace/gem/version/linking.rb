class Namespace::Gem::Version::Linking < ApplicationRecord
  belongs_to :version
  belongs_to :link
end
