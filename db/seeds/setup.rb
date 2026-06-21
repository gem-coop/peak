loader.defaults created_by_id: -> { Peak.system_user.id }, created_by_type: "User", summary: "",
  platform_id: -> { Peak::Platform.default.id }, approved_at: -> { Time.current }

Oaken::Stored::ActiveRecord.include loader.context
def fixture_upload(filename) = Peak::Gem::Upload.read(fixture_file(filename))
def fixture_file(filename)   = Rails.root.join("test/fixtures/files").join(filename)

register OIDC::Provider, as: :oidc_providers
register TrustedPublisher, as: :trusted_publishers

register Peak::Terms, as: :terms
terms.proxy *Peak::Terms.statuses.keys

register Namespace::Access, as: :accesses
register Namespace::Index, as: :indexes
register Namespace::Index::Cooldown, as: :cooldowns
register Namespace::Gem, as: :gems
register Namespace::Gem::Version, as: :versions
register Namespace::Gem::Version::Reference, as: :references

def users.create(label = nil, unique_by: :email_address, **) = super
def namespaces.create(label = nil, unique_by: :name, **) = super
def gems.create(label = nil, unique_by: [:index, :name], **) = super

indexes.proxy :public_access, :private_access
def indexes.create(label = nil, unique_by: [:namespace, :slug], **) = super

accesses.proxy(*Namespace::Access.roles.keys)
def accesses.create(label = nil, unique_by: [:namespace, :user], **) = super

versions.with do
  # TODO: Figure out why we need `versions.` here for it to work.
  def versions.create(label = nil, unique_by: [:gem, :ref], **) = super

  def upload(gem, ref:, **)
    create(gem:, ref:, line: "", **).tap {
      _1.process fixture_upload("#{gem.name}/#{_1.filename}") }
  end

  def by(gem, ref:) = type.find_by!(gem:, ref:)
end
