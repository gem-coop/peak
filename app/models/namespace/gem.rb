class Namespace::Gem < ApplicationRecord
  belongs_to :namespace
  has_many :versions

  has_many :referrants, class_name: "Version::Reference", foreign_key: :name, primary_key: :name

  def to_param = name
end
