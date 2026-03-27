class Peak::Platform < ApplicationRecord
  ARCH = %w[arm arm64 aarch64 x64 x86 x86_64 i386 mswin32 universal]
  ARCH.each do |arch|
    scope arch, -> { where(arch:) }
    class_eval "def #{arch}? = arch == '#{arch}'"
  end

  NAMES = %w[ruby java jruby linux darwin mswin32]
  NAMES.each do |name|
    scope name, -> { where(name:) }
    class_eval "def #{name}? = name == '#{name}'"
  end

  scope :pure, -> { where(arch: "", specifier: "") }

  scope :precompile_targeted, -> { where(precompile_target: true) }
  before_create :set_details, :set_precompile_target

  has_many :versions, class_name: "Namespace::Gem::Version"

  def self.default = find_or_create_by!(key: "ruby")

  def self.ids_from(keys)
    upsert_all Array(keys).map { { key: _1, **split(_1) } }
  end

  def self.upsert_all(values)
    # Also collect already inserted ids with `update_only:`.
    super(values, update_only: %i[arch name specifier], returning: :id,
      unique_by: :peak_platforms_uniqueness).rows.flat_map(&:first)
  end

  def self.split(key)
    arch, name, specifier = key.split("-", 3)
    name, arch = arch, nil if name.nil?

    { arch: arch.to_s, name: name.to_s, specifier: specifier.to_s }
  end

  private
    def set_details
      assign_attributes self.class.split(key)
    end

    def set_precompile_target
      self.precompile_target = darwin? && arm64?
    end
end
