class Namespace < ApplicationRecord
  include Search::Indexed
  def indexing_content = name

  has_many :submissions, foreign_key: :name, primary_key: :name

  has_many :accesses, dependent: :destroy
  has_many :users, through: :accesses

  has_many :ownerships, -> { owner }, class_name: "Access"
  has_many :owners, through: :ownerships, source: :user

  has_many :indexes, dependent: :destroy
  has_one_built :default_index, -> { public_access.where(slug: :default) }, class_name: "Index"

  def self.named(name) = find_by!(name:)
  def to_param = name
end
