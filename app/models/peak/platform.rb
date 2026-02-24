class Peak::Platform < ApplicationRecord
  ARCH = %w[arm arm64 aarch64 x64 x86 x86_64 i386 mswin32 universal]
  ARCH.each { class_eval "def #{_1}? = arch == '#{_1}'" }

  NAMES = %w[ruby java jruby linux darwin mswin32]
  NAMES.each { class_eval "def #{_1}? = name == '#{_1}'" }

  scope :precompile_targeted, -> { where(precompile_target: true) }
  before_create :set_details, :set_precompile_target

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
    arch, name, specifier = key.split("-")
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
