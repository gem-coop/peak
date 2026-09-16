

loader.defaults summary: "",
  created_by_id: -> { Peak.system_user.id },
  platform_id: -> { Peak::Platform.default.id },
  email_address_verified_at: -> { Time.current }

Oaken::Stored::ActiveRecord.include loader.context
def fixture_upload(filename) = Peak::Gem::Upload.read(fixture_file(filename))
def fixture_file(filename)   = Rails.root.join("test/fixtures/files").join(filename)

register Peak::EmailAddress::DisposedDomain, as: :disposed_domains
register Peak::Terms, as: :terms
terms.proxy *Peak::Terms.statuses.keys

register Namespace::Access, as: :accesses
register Namespace::Submission, as: :submissions
register Namespace::Index, as: :indexes
register Namespace::Index::Cooldown, as: :cooldowns
register Namespace::Gem, as: :gems
register Namespace::Gem::Version, as: :versions
register Namespace::Gem::Version::Reference, as: :references

def users.create(label = nil, unique_by: :email_address, **) = super
def gems.create(label = nil, unique_by: [:namespace, :name], **) = super

def namespaces.create_approved(label = nil, owner: Peak.system_user, **) = create(label, **).tap do
  accesses.owner.create(namespace: _1, user: owner)
  submissions.approved.create(name: _1.name, owner:, resolved_at: Time.current)
end
def namespaces.create(label = nil, unique_by: :name, **) = super

indexes.proxy :public_access, :private_access
def indexes.create(label = nil, unique_by: [:namespace, :slug], **) = super

def cooldowns.create(label = nil, unique_by: [:index], **) = super

accesses.proxy(*Namespace::Access.roles.keys)
def accesses.create(label = nil, unique_by: [:namespace, :user], **) = super

submissions.defaults owner: -> { users.owner }
submissions.proxy(*Namespace::Submission.statuses.keys)

def submissions.create(label = nil, unique_by: [:name], **) = super

versions.with do
  # TODO: Figure out why we need `versions.` here for it to work.
  def versions.create(label = nil, unique_by: [:gem, :ref], **) = super

  def upload(gem, ref:, **)
    create(gem:, ref:, line: "", **).tap {
      _1.process fixture_upload("#{gem.name}/#{_1.filename}") }
  end

  def by(gem, ref:) = type.find_by!(gem:, ref:)
end

def users.unverified = with(email_address_verified_at: nil)
