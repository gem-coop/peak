class Namespace::Gem::Version < ApplicationRecord
  belongs_to :gem
  has_one :metadata

  has_many :nodes
  has_many :references, through: :nodes
  has_many :referrants, -> { where(ref: _1.ref) }, through: :gem, foreign_key: :ref, primary_key: :ref

  scope :for, -> { joins(:gem).where(gem: {name: _1}) }

  has_one_attached :package

  attribute :published_at, default: -> { Time.current }

  def to_param = package_name

  def package_name = "#{name}.gem"
  def name = "#{gem.name}-#{ref}"

  def line
    "#{ref} #{references.line}#{metadata_part}\n"
  end

  def metadata_part
    details = metadata&.slice(:checksum, :ruby, :rubygems).to_h.merge(published_at:).compact_blank.as_json
    details.map { "#{_1}:#{_2}" }.join(",").presence&.then { "|#{_1}" }
  end
end
