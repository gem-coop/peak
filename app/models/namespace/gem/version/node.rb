class Namespace::Gem::Version::Node < ApplicationRecord
  belongs_to :version
  belongs_to :reference
end
