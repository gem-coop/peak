class Peak::Gem::Gemspec
  attr_reader :spec

  def initialize(spec)
    @spec = spec
    @spec.metadata ||= {} # Some specs have nil metadata but are otherwise valid, so we shimmy them a bit.
  end

  def tmpfile = nil
  def checksum = nil
  def published_at = nil

  def slice(*keys)
    keys.index_with { public_send _1 }
  end

  class_eval do
    # TODO: Support @namespace/gem format in names, particularly in requirement_triples.
    def self.valid_name?(name)     = Peak::Gem.name?(name)
    def self.valid_operator?(op)   = Peak::Gem.operator_values.include?(op)
    def self.valid_chars?(*values) = values.none?(/[\r\n\x00]/)
    def self.valid_ref?(ref)       = ref.present? && ::Gem::Version::ANCHORED_VERSION_PATTERN.match?(ref)
    delegate :valid_name?, :valid_operator?, :valid_chars?, :valid_ref?, to: :class

    class InvalidError < StandardError; end

    class Validator < Gem::SpecificationPolicy
      def validate
        Gem::DefaultUserInteraction.use_ui(Gem::SilentUI.new) { super }
      end
      def validate_non_files = nil
    end

    def validate
      raise InvalidError unless valid_name?(name)
      raise InvalidError unless valid_ref?(ref)
      raise InvalidError unless valid_chars?(checksum, *ruby, *rubygems, *executables, *licenses)
      raise InvalidError unless requirement_triples.all? { valid_name?(_1) && valid_operator?(_2) && valid_ref?(_3) }
      Validator.new(spec).validate
      self
    rescue Gem::InvalidSpecificationException
      raise InvalidError
    end
  end

  delegate :name, :executables, :licenses, :summary, :metadata, to: :spec
  def ruby = spec.required_ruby_version&.as_list
  def rubygems = spec.required_rubygems_version&.as_list

  def platform_id
    Peak::Platform.ids_from(platform_key).first
  end
  def platform_key = spec.platform.to_s
  def platform_ref = "#{ref}-#{spec.platform}".chomp("-ruby")

  def ref = spec.version.to_s

  def requirement_triples
    @requirement_triples ||= begin
      dependencies = spec.dependencies.map { _1.is_a?(Gem::Dependency) ? _1 : Gem::Dependency.new(_1, _2) }.select(&:runtime?)
      dependencies.flat_map { |dep|
        dep.requirement.requirements.map { |operator, ref| [dep.name, operator, ref.to_s] }
      }.uniq
    end
  end

  def links
    metadata.to_h.select { _1.end_with?("_uri") }
      .to_h { [_1.delete_suffix("_uri").to_sym, Peak::Gem::Link.parse(_2)] }
      .merge(homepage:).compact_blank
  end
  def homepage = Peak::Gem::Link.parse(spec.homepage)

  def has_extensions? = spec.extensions.any?
  alias_method :has_extensions, :has_extensions?
end
