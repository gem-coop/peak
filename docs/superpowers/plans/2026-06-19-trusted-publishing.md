# Trusted Publishing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let CI exchange a short-lived GitHub Actions OIDC JWT for a scoped, short-lived push token instead of storing a secret, with gem-scoped and pending trusted publishers, owner-managed UI, and Avo admin.

**Architecture:** A pluggable `OIDC::Provider` registry (GitHub Actions first) verifies JWTs against cached JWKS. `TrustedPublisher` (STI; `TrustedPublisher::GitHubActions`) records the trusted config per gem (or pending, by reserved name). `OIDC::TokenExchange` matches a verified JWT to a publisher and mints a `TrustedPublisher::PushKey` (distinct token prefix). The existing namespace-scoped push endpoint dispatches on token prefix; `Namespace::Gem::Version#created_by` becomes polymorphic so a push can be attributed to a publisher.

**Tech Stack:** Rails 8.1, Ruby 4.0.5, Postgres, Minitest + Oaken seeds, WebMock, HTTPX (HTTP client), `jwt` gem (new), Avo (admin), `strong_migrations`.

## Global Constraints

- Ruby `4.0.5`; Rails migrations use `ActiveRecord::Migration[8.1]`.
- Migrations must pass `strong_migrations` (`start_after = 20260227200923`). Use timestamps after that. Add columns with constant defaults (PG-safe); never add a `NOT NULL` column without a default on a populated table.
- HTTP calls use `HTTPX` (not Faraday/Net::HTTP). Tests stub HTTP with WebMock.
- Tests use Oaken seed accessors (`users.owner`, `namespaces.gemcoop`, `gems.peak`, `oidc_providers.github`), not fixtures. No `users(:x)` fixture syntax.
- Test host (`Peak.host`) is `"example.com"`. JWT `aud` must equal `Peak.host`.
- Custom macros: `performs` (active_job-performs), `has_object` (active_record-associated_object), `has_one_built` (app macro in `ApplicationRecord`). Reuse, don't reinvent.
- View responses use `render Peak::Status("…")` / `render Peak::Error("…")`. Plain push responses use `render plain: "…"` and must be non-empty (Bundler requires body text).
- TP push token prefix constant: `TrustedPublisher::PushKey::PREFIX = "gemcoop_tp_"`.
- Commits use `jj commit -m "…"` (repo uses Jujutsu). End each commit message with a blank line then:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- TP push key TTL: `30.minutes`. User push key TTL stays `24.hours`.

---

## File Structure

**Create:**
- `app/models/oidc.rb` — `OIDC` module, sets `table_name_prefix = "oidc_"`.
- `app/models/oidc/provider.rb` — STI base: issuer registry, JWKS fetch/cache (HTTPX), JWT verify+decode.
- `app/models/oidc/provider/github_actions.rb` — STI subclass: GitHub issuer constant, audience default.
- `app/models/oidc/id_token.rb` — audit record + replay protection (`jti` uniqueness).
- `app/models/oidc/token_exchange.rb` — PORO service: JWT → matched publisher → minted key.
- `app/models/trusted_publisher.rb` — STI base: namespace/gem/provider associations, `pending?`, `target_index`, `link_gem!`.
- `app/models/trusted_publisher/github_actions.rb` — STI subclass: claim columns + `matches?(claims)`.
- `app/models/trusted_publisher/push_key.rb` — minted credential, prefixed token.
- `app/models/concerns/expiring_token.rb` — shared `active`/`expired?` for push-key classes.
- `app/controllers/namespaces/oidc/exchanges_controller.rb` — `POST …/exchange_token`.
- `app/controllers/namespaces/gems/trusted_publishers_controller.rb` — gem-scoped publisher UI.
- `app/controllers/namespaces/trusted_publishers_controller.rb` — pending publisher UI.
- `app/controllers/concerns/namespace_authorization.rb` — owner gate.
- Views under `app/views/namespaces/gems/trusted_publishers/` and `app/views/namespaces/trusted_publishers/`.
- Avo: `app/avo/resources/{trusted_publisher,oidc_provider,oidc_id_token,trusted_publisher_push_key}.rb` + matching `app/controllers/avo/*` controllers.
- `db/seeds/data/oidc.rb` — seed GitHub Actions provider.
- Migrations under `db/migrate/`.

**Modify:**
- `Gemfile` — add `gem "jwt"`.
- `app/models/user/push_key.rb` — include `ExpiringToken`.
- `app/models/namespace/gem/version.rb` — polymorphic `created_by`.
- `app/controllers/namespaces/gems_controller.rb` — prefix-dispatch auth, scope enforcement, polymorphic attribution, pending conversion.
- `config/routes.rb` — exchange route + UI routes.
- `db/seeds/setup.rb` — register `OIDC::Provider` and `TrustedPublisher`; add `created_by_type` default.
- `test/test_helper.rb` — add OIDC test helpers.

---

## Task 1: Add the `jwt` gem and the `OIDC` module namespace

**Files:**
- Modify: `Gemfile`
- Create: `app/models/oidc.rb`
- Test: `test/models/oidc_test.rb`

**Interfaces:**
- Produces: `OIDC` module with `OIDC.table_name_prefix == "oidc_"`; `jwt` gem available (`require "jwt"`).

- [ ] **Step 1: Add the gem**

In `Gemfile`, after the `gem "httpx", "~> 1.8"` line, add:

```ruby
# Decode and verify OIDC ID tokens for trusted publishing
gem "jwt", "~> 3.1"
```

- [ ] **Step 2: Install**

Run: `bin/bundle install`
Expected: resolves and writes `jwt` into `Gemfile.lock`.

- [ ] **Step 3: Create the module**

Create `app/models/oidc.rb`:

```ruby
module OIDC
  def self.table_name_prefix = "oidc_"
end
```

- [ ] **Step 4: Write the test**

Create `test/models/oidc_test.rb`:

```ruby
require "test_helper"

class OIDCTest < ActiveSupport::TestCase
  test "table name prefix" do
    assert_equal "oidc_", OIDC.table_name_prefix
  end

  test "jwt is loadable" do
    assert defined?(JWT)
  end
end
```

- [ ] **Step 5: Run the test**

Run: `bin/rails test test/models/oidc_test.rb`
Expected: PASS (2 assertions).

- [ ] **Step 6: Commit**

```bash
jj commit -m "Add jwt gem and OIDC module namespace

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: OIDC::Provider registry with JWKS verification

**Files:**
- Create: `db/migrate/20260619000001_create_oidc_providers.rb`
- Create: `app/models/oidc/provider.rb`
- Create: `app/models/oidc/provider/github_actions.rb`
- Modify: `db/seeds/setup.rb`, `db/seeds/data/oidc.rb` (create), `test/test_helper.rb`
- Test: `test/models/oidc/provider_test.rb`

**Interfaces:**
- Produces:
  - `OIDC::Provider` columns: `type:string`, `name:string`, `issuer:string` (unique).
  - `OIDC::Provider::GitHubActions::ISSUER == "https://token.actions.githubusercontent.com"`.
  - `OIDC::Provider#jwks -> Hash` (`{ "keys" => [...] }`, cached 5 min).
  - `OIDC::Provider#decode(jwt, audience:) -> Hash` (verified claims) or raises `JWT::DecodeError`.
  - `OIDC::Provider.for_issuer(iss) -> OIDC::Provider` (raises `ActiveRecord::RecordNotFound`).
  - Test helpers in `test/test_helper.rb`: `oidc_rsa_key`, `oidc_jwk`, `stub_oidc_discovery(provider)`, `build_github_jwt(claims = {})`, `default_github_claims`.
  - Oaken accessor `oidc_providers.github`.

- [ ] **Step 1: Write the migration**

Create `db/migrate/20260619000001_create_oidc_providers.rb`:

```ruby
class CreateOidcProviders < ActiveRecord::Migration[8.1]
  def change
    create_table :oidc_providers do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :issuer, null: false

      t.timestamps
      t.index :issuer, unique: true
    end
  end
end
```

- [ ] **Step 2: Run the migration**

Run: `bin/rails db:migrate`
Expected: creates `oidc_providers`; updates `db/schema.rb`.

- [ ] **Step 3: Write the provider models**

Create `app/models/oidc/provider.rb`:

```ruby
class OIDC::Provider < ApplicationRecord
  has_many :trusted_publishers, dependent: :restrict_with_exception

  JWKS_CACHE_TTL = 5.minutes

  def self.for_issuer(issuer) = find_by!(issuer:)

  # Verifies signature (RS256), issuer, audience, and time claims; returns the decoded payload.
  def decode(jwt, audience:)
    payload, _header = JWT.decode(jwt, nil, true,
      algorithms: %w[RS256],
      jwks: jwks,
      iss: issuer, verify_iss: true,
      aud: audience, verify_aud: true,
      verify_expiration: true,
      verify_not_before: true,
      verify_iat: true)
    payload
  end

  def jwks
    Rails.cache.fetch("oidc/jwks/#{issuer}", expires_in: JWKS_CACHE_TTL) do
      fetch_json(discovery.fetch("jwks_uri"))
    end
  end

  private
    def discovery
      fetch_json("#{issuer}/.well-known/openid-configuration")
    end

    def fetch_json(url)
      response = HTTPX.get(url)
      raise JWT::DecodeError, "OIDC fetch failed: #{url} (#{response.status})" unless response.status == 200
      JSON.parse(response.body.to_s)
    end
end
```

Create `app/models/oidc/provider/github_actions.rb`:

```ruby
class OIDC::Provider::GitHubActions < OIDC::Provider
  ISSUER = "https://token.actions.githubusercontent.com"
end
```

- [ ] **Step 4: Register and seed the provider**

In `db/seeds/setup.rb`, add after the existing `register …` lines:

```ruby
register OIDC::Provider, as: :oidc_providers
register TrustedPublisher, as: :trusted_publishers
```

Create `db/seeds/data/oidc.rb`:

```ruby
oidc_providers.label github: OIDC::Provider::GitHubActions.create_or_find_by!(
  issuer: OIDC::Provider::GitHubActions::ISSUER
) { _1.name = "GitHub Actions" }
```

> Note: `TrustedPublisher` is registered now but its model arrives in Task 3. Run this task's tests only after Task 3 if Oaken eager-loads the constant; if `bin/rails test` fails on the missing `TrustedPublisher` constant, move the `register TrustedPublisher` line to Task 3 Step 1.

- [ ] **Step 5: Add test helpers**

In `test/test_helper.rb`, inside `class ActiveSupport::TestCase`, add:

```ruby
  def oidc_rsa_key = @oidc_rsa_key ||= OpenSSL::PKey::RSA.generate(2048)
  def oidc_jwk = JWT::JWK.new(oidc_rsa_key, kid: "test-kid")

  def stub_oidc_discovery(issuer = OIDC::Provider::GitHubActions::ISSUER)
    WebMock.stub_request(:get, "#{issuer}/.well-known/openid-configuration")
      .to_return(status: 200, body: { jwks_uri: "#{issuer}/jwks" }.to_json,
        headers: { "Content-Type" => "application/json" })
    WebMock.stub_request(:get, "#{issuer}/jwks")
      .to_return(status: 200, body: { keys: [oidc_jwk.export] }.to_json,
        headers: { "Content-Type" => "application/json" })
  end

  def default_github_claims(**overrides)
    {
      "iss" => OIDC::Provider::GitHubActions::ISSUER,
      "aud" => Peak.host,
      "jti" => SecureRandom.uuid,
      "iat" => Time.current.to_i,
      "nbf" => Time.current.to_i,
      "exp" => 5.minutes.from_now.to_i,
      "repository" => "gem-coop/peak",
      "repository_owner" => "gem-coop",
      "job_workflow_ref" => "gem-coop/peak/.github/workflows/release.yml@refs/heads/main",
      "ref" => "refs/heads/main",
      "environment" => "rubygems"
    }.merge(overrides.transform_keys(&:to_s))
  end

  def build_github_jwt(claims = {})
    JWT.encode(default_github_claims(**claims), oidc_rsa_key, "RS256", kid: oidc_jwk.kid)
  end
```

Add `require "openssl"` near the top of `test/test_helper.rb` if not already implied.

- [ ] **Step 6: Write the provider test**

Create `test/models/oidc/provider_test.rb`:

```ruby
require "test_helper"

class OIDC::ProviderTest < ActiveSupport::TestCase
  setup { @provider = oidc_providers.github }

  test "for_issuer" do
    assert_equal @provider, OIDC::Provider.for_issuer(OIDC::Provider::GitHubActions::ISSUER)
  end

  test "decode verifies a valid jwt" do
    stub_oidc_discovery
    payload = @provider.decode(build_github_jwt, audience: Peak.host)
    assert_equal "gem-coop/peak", payload["repository"]
  end

  test "decode rejects wrong audience" do
    stub_oidc_discovery
    jwt = build_github_jwt(aud: "wrong.example")
    assert_raises(JWT::InvalidAudError) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "decode rejects expired jwt" do
    stub_oidc_discovery
    jwt = build_github_jwt(exp: 5.minutes.ago.to_i)
    assert_raises(JWT::ExpiredSignature) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "decode rejects bad signature" do
    stub_oidc_discovery
    other = OpenSSL::PKey::RSA.generate(2048)
    jwt = JWT.encode(default_github_claims, other, "RS256", kid: oidc_jwk.kid)
    assert_raises(JWT::DecodeError) { @provider.decode(jwt, audience: Peak.host) }
  end

  test "jwks is cached" do
    stub_oidc_discovery
    @provider.jwks
    @provider.jwks
    assert_requested :get, "#{@provider.issuer}/jwks", times: 1
  end
end
```

- [ ] **Step 7: Run tests**

Run: `bin/rails test test/models/oidc/provider_test.rb`
Expected: PASS (all). If the JWKS cache test fails because the test cache is disabled, add to `setup`: `Rails.cache.clear` and confirm `config/environments/test.rb` uses `:memory_store` (it does).

- [ ] **Step 8: Commit**

```bash
jj commit -m "Add OIDC::Provider registry with JWKS verification

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: TrustedPublisher model with claim matching

**Files:**
- Create: `db/migrate/20260619000002_create_trusted_publishers.rb`
- Create: `app/models/trusted_publisher.rb`
- Create: `app/models/trusted_publisher/github_actions.rb`
- Test: `test/models/trusted_publisher/github_actions_test.rb`

**Interfaces:**
- Consumes: `OIDC::Provider` (Task 2); `Namespace`, `Namespace::Gem`, `Namespace#default_index`.
- Produces:
  - `trusted_publishers` columns: `type:string`, `namespace:references null:false`, `gem:references null:true` (`namespace_gem`), `gem_name:string null:false`, `provider:references null:false` (`oidc_provider`), `repository_owner:string`, `repository_name:string`, `workflow_filename:string`, `environment:string null:true`, `ref:string null:true`.
  - `TrustedPublisher#pending? -> Boolean` (gem nil).
  - `TrustedPublisher#target_index -> Namespace::Index` (`gem&.index || namespace.default_index`).
  - `TrustedPublisher#link_gem!(gem)` — sets gem if pending and names match.
  - `TrustedPublisher::GitHubActions#matches?(claims_hash) -> Boolean`.

- [ ] **Step 1: Write the migration**

Create `db/migrate/20260619000002_create_trusted_publishers.rb`:

```ruby
class CreateTrustedPublishers < ActiveRecord::Migration[8.1]
  def change
    create_table :trusted_publishers do |t|
      t.string :type, null: false
      t.references :namespace, null: false, foreign_key: true
      t.references :gem, null: true, foreign_key: { to_table: :namespace_gems }
      t.string :gem_name, null: false
      t.references :provider, null: false, foreign_key: { to_table: :oidc_providers }

      # GitHub Actions claim policy
      t.string :repository_owner
      t.string :repository_name
      t.string :workflow_filename
      t.string :environment
      t.string :ref

      t.timestamps
    end
  end
end
```

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`
Expected: creates `trusted_publishers`.

- [ ] **Step 3: Write the models**

Create `app/models/trusted_publisher.rb`:

```ruby
class TrustedPublisher < ApplicationRecord
  belongs_to :namespace
  belongs_to :gem, class_name: "Namespace::Gem", optional: true
  belongs_to :provider, class_name: "OIDC::Provider"

  has_many :push_keys, dependent: :destroy

  validates :gem_name, presence: true

  scope :pending, -> { where(gem_id: nil) }

  def pending? = gem_id.nil?
  def target_index = gem&.index || namespace.default_index

  def link_gem!(gem)
    update!(gem:) if pending? && gem.name == gem_name
  end

  # Subclasses implement #matches?(claims) for their provider's claim shape.
  def matches?(_claims) = raise NotImplementedError
end
```

Create `app/models/trusted_publisher/github_actions.rb`:

```ruby
class TrustedPublisher::GitHubActions < TrustedPublisher
  validates :repository_owner, :repository_name, :workflow_filename, presence: true

  def matches?(claims)
    claims["repository_owner"] == repository_owner &&
      claims["repository"] == "#{repository_owner}/#{repository_name}" &&
      workflow_matches?(claims) &&
      optional_matches?(environment, claims["environment"]) &&
      optional_matches?(ref, claims["ref"])
  end

  private
    def workflow_matches?(claims)
      prefix = "#{repository_owner}/#{repository_name}/.github/workflows/"
      job_ref = claims["job_workflow_ref"].to_s
      return false unless job_ref.start_with?(prefix)
      job_ref.delete_prefix(prefix).split("@", 2).first == workflow_filename
    end

    def optional_matches?(configured, claim_value)
      configured.blank? || configured == claim_value
    end
end
```

- [ ] **Step 4: Write the test**

Create `test/models/trusted_publisher/github_actions_test.rb`:

```ruby
require "test_helper"

class TrustedPublisher::GitHubActionsTest < ActiveSupport::TestCase
  def build(**overrides)
    TrustedPublisher::GitHubActions.new({
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak",
      workflow_filename: "release.yml"
    }.merge(overrides))
  end

  test "pending? and target_index" do
    assert_not build.pending?
    assert_equal gems.peak.index, build.target_index

    pending = build(gem: nil)
    assert pending.pending?
    assert_equal namespaces.gemcoop.default_index, pending.target_index
  end

  test "matches exact claims" do
    assert build.matches?(default_github_claims)
  end

  test "rejects wrong repository" do
    assert_not build.matches?(default_github_claims(repository: "evil/peak", repository_owner: "evil"))
  end

  test "rejects wrong workflow" do
    refute build.matches?(default_github_claims(
      job_workflow_ref: "gem-coop/peak/.github/workflows/evil.yml@refs/heads/main"))
  end

  test "environment is enforced only when configured" do
    assert build.matches?(default_github_claims(environment: "anything"))
    assert build(environment: "rubygems").matches?(default_github_claims(environment: "rubygems"))
    refute build(environment: "rubygems").matches?(default_github_claims(environment: "other"))
  end

  test "link_gem! converts a pending publisher" do
    pending = build(gem: nil)
    pending.save!
    pending.link_gem!(gems.peak)
    assert_equal gems.peak, pending.reload.gem
    assert_not pending.pending?
  end

  test "link_gem! ignores name mismatch" do
    pending = build(gem: nil, gem_name: "other")
    pending.save!
    pending.link_gem!(gems.peak)
    assert pending.reload.pending?
  end
end
```

- [ ] **Step 5: Run**

Run: `bin/rails test test/models/trusted_publisher/github_actions_test.rb`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
jj commit -m "Add TrustedPublisher with GitHub Actions claim matching

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Extract ExpiringToken concern from User::PushKey

**Files:**
- Create: `app/models/concerns/expiring_token.rb`
- Modify: `app/models/user/push_key.rb`
- Test: `test/models/user/push_key_test.rb` (already exists — must keep passing)

**Interfaces:**
- Produces: `ExpiringToken` concern providing scopes `active`/`expired` and methods `active?`/`expired?`, keyed off an `expires_at` column. Including classes must define their own `expires_at` default.

- [ ] **Step 1: Create the concern**

Create `app/models/concerns/expiring_token.rb`:

```ruby
module ExpiringToken
  extend ActiveSupport::Concern

  included do
    scope :active,  -> { where(expires_at: Time.current..).order(expires_at: :desc) }
    scope :expired, -> { where(expires_at: ..Time.current) }
  end

  def active? = !expired?
  def expired? = expires_at.past?
end
```

- [ ] **Step 2: Refactor User::PushKey**

Replace `app/models/user/push_key.rb` with:

```ruby
class User::PushKey < ApplicationRecord
  include ExpiringToken

  belongs_to :user
  attribute :expires_at, default: -> { 24.hours.from_now }

  performs :destroy

  has_secure_token

  def sign_in_mailer
    Mailer.with(push_key: self).sign_in
  end
end
```

- [ ] **Step 3: Run the existing push-key test**

Run: `bin/rails test test/models/user/push_key_test.rb`
Expected: PASS (unchanged behavior — scopes and predicates now come from the concern).

- [ ] **Step 4: Commit**

```bash
jj commit -m "Extract ExpiringToken concern from User::PushKey

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: TrustedPublisher::PushKey minted credential

**Files:**
- Create: `db/migrate/20260619000003_create_trusted_publisher_push_keys.rb`
- Create: `app/models/trusted_publisher/push_key.rb`
- Test: `test/models/trusted_publisher/push_key_test.rb`

**Interfaces:**
- Consumes: `ExpiringToken` (Task 4), `TrustedPublisher` (Task 3).
- Produces:
  - `trusted_publisher_push_keys` columns: `trusted_publisher:references null:false`, `token:string null:false` (unique), `expires_at:datetime null:false`.
  - `TrustedPublisher::PushKey::PREFIX == "gemcoop_tp_"`, `TTL == 30.minutes`.
  - `TrustedPublisher::PushKey::SCOPES == %w[push_rubygem]`.
  - `#name -> String` (`"trusted-publisher:<gem_name>"`); `#scopes -> Array`.
  - Token always begins with `PREFIX`.

- [ ] **Step 1: Write the migration**

Create `db/migrate/20260619000003_create_trusted_publisher_push_keys.rb`:

```ruby
class CreateTrustedPublisherPushKeys < ActiveRecord::Migration[8.1]
  def change
    create_table :trusted_publisher_push_keys do |t|
      t.references :trusted_publisher, null: false, foreign_key: true
      t.string :token, null: false
      t.datetime :expires_at, null: false

      t.timestamps
      t.index :token, unique: true
    end
  end
end
```

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`
Expected: creates `trusted_publisher_push_keys`.

- [ ] **Step 3: Write the model**

Create `app/models/trusted_publisher/push_key.rb`:

```ruby
class TrustedPublisher::PushKey < ApplicationRecord
  self.table_name = "trusted_publisher_push_keys"

  include ExpiringToken

  PREFIX = "gemcoop_tp_"
  TTL = 30.minutes
  SCOPES = %w[push_rubygem].freeze

  belongs_to :trusted_publisher

  attribute :expires_at, default: -> { TTL.from_now }
  before_validation :generate_token, on: :create
  validates :token, presence: true, format: /\A#{PREFIX}/

  delegate :gem_name, :target_index, :namespace, to: :trusted_publisher

  def name = "trusted-publisher:#{gem_name}"
  def scopes = SCOPES

  private
    def generate_token
      self.token ||= "#{PREFIX}#{SecureRandom.urlsafe_base64(32)}"
    end
end
```

- [ ] **Step 4: Write the test**

Create `test/models/trusted_publisher/push_key_test.rb`:

```ruby
require "test_helper"

class TrustedPublisher::PushKeyTest < ActiveSupport::TestCase
  setup do
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    @key = @publisher.push_keys.create!
  end

  test "token has prefix" do
    assert @key.token.start_with?(TrustedPublisher::PushKey::PREFIX)
  end

  test "default expiry is 30 minutes" do
    freeze_time
    assert_equal 30.minutes.from_now, @publisher.push_keys.build.expires_at
  end

  test "active scope and predicates" do
    assert_includes TrustedPublisher::PushKey.active, @key
    travel @key.expires_at.to_i + 1.second
    refute @key.active?
    assert_includes TrustedPublisher::PushKey.expired, @key
  end

  test "name and scopes" do
    assert_equal "trusted-publisher:peak", @key.name
    assert_equal %w[push_rubygem], @key.scopes
  end
end
```

- [ ] **Step 5: Run**

Run: `bin/rails test test/models/trusted_publisher/push_key_test.rb`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
jj commit -m "Add TrustedPublisher::PushKey minted credential

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: OIDC::IdToken audit + replay protection

**Files:**
- Create: `db/migrate/20260619000004_create_oidc_id_tokens.rb`
- Create: `app/models/oidc/id_token.rb`
- Test: `test/models/oidc/id_token_test.rb`

**Interfaces:**
- Consumes: `OIDC::Provider`, `TrustedPublisher`, `TrustedPublisher::PushKey`.
- Produces:
  - `oidc_id_tokens` columns: `provider:references null:false` (`oidc_provider`), `trusted_publisher:references null:false`, `push_key:references null:true` (`trusted_publisher_push_key`), `jti:string null:false`, `claims:json null:false default:{}`.
  - Unique index on `[provider_id, jti]` (replay protection).

- [ ] **Step 1: Write the migration**

Create `db/migrate/20260619000004_create_oidc_id_tokens.rb`:

```ruby
class CreateOidcIdTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :oidc_id_tokens do |t|
      t.references :provider, null: false, foreign_key: { to_table: :oidc_providers }
      t.references :trusted_publisher, null: false, foreign_key: true
      t.references :push_key, null: true, foreign_key: { to_table: :trusted_publisher_push_keys }
      t.string :jti, null: false
      t.json :claims, null: false, default: {}

      t.timestamps
      t.index [:provider_id, :jti], unique: true
    end
  end
end
```

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`
Expected: creates `oidc_id_tokens`.

- [ ] **Step 3: Write the model**

Create `app/models/oidc/id_token.rb`:

```ruby
class OIDC::IdToken < ApplicationRecord
  belongs_to :provider, class_name: "OIDC::Provider"
  belongs_to :trusted_publisher
  belongs_to :push_key, class_name: "TrustedPublisher::PushKey", optional: true

  validates :jti, presence: true, uniqueness: { scope: :provider_id }
end
```

- [ ] **Step 4: Write the test**

Create `test/models/oidc/id_token_test.rb`:

```ruby
require "test_helper"

class OIDC::IdTokenTest < ActiveSupport::TestCase
  setup do
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  test "jti is unique per provider" do
    attrs = { provider: oidc_providers.github, trusted_publisher: @publisher, jti: "abc", claims: {} }
    OIDC::IdToken.create!(attrs)
    assert_raises(ActiveRecord::RecordInvalid) { OIDC::IdToken.create!(attrs) }
  end
end
```

- [ ] **Step 5: Run**

Run: `bin/rails test test/models/oidc/id_token_test.rb`
Expected: PASS.

- [ ] **Step 6: Commit**

```bash
jj commit -m "Add OIDC::IdToken audit and replay protection

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 7: Make Version#created_by polymorphic

**Files:**
- Create: `db/migrate/20260619000005_make_version_created_by_polymorphic.rb`
- Modify: `app/models/namespace/gem/version.rb`, `db/seeds/setup.rb`
- Test: `test/models/namespace/gem/version_test.rb`

**Interfaces:**
- Consumes: `TrustedPublisher` (Task 3).
- Produces: `Namespace::Gem::Version#created_by` accepts a `User` or a `TrustedPublisher`. New column `created_by_type:string null:false default:"User"`; composite index `[created_by_type, created_by_id]`.

- [ ] **Step 1: Write the migration**

Create `db/migrate/20260619000005_make_version_created_by_polymorphic.rb`:

```ruby
class MakeVersionCreatedByPolymorphic < ActiveRecord::Migration[8.1]
  def change
    # Constant default is PG-safe on a populated table and backfills existing rows to "User".
    add_column :namespace_gem_versions, :created_by_type, :string, null: false, default: "User"
    add_index :namespace_gem_versions, [:created_by_type, :created_by_id]
  end
end
```

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`
Expected: adds `created_by_type` defaulting to `"User"`; existing rows backfilled.

- [ ] **Step 3: Update the model**

In `app/models/namespace/gem/version.rb`, change:

```ruby
belongs_to :created_by, class_name: "User"
```

to:

```ruby
belongs_to :created_by, polymorphic: true
```

- [ ] **Step 4: Update the Oaken default**

In `db/seeds/setup.rb`, change the first line:

```ruby
loader.defaults created_by_id: -> { Peak.system_user.id }, summary: "",
```

to:

```ruby
loader.defaults created_by_id: -> { Peak.system_user.id }, created_by_type: "User", summary: "",
```

- [ ] **Step 5: Add a polymorphic-attribution test**

Append to `test/models/namespace/gem/version_test.rb`:

```ruby
  test "created_by can be a trusted publisher" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")

    version = versions.by gems.peak, ref: "0.1.0"
    version.update!(created_by: publisher)
    assert_equal publisher, version.reload.created_by
  end
```

- [ ] **Step 6: Run**

Run: `bin/rails test test/models/namespace/gem/version_test.rb test/controllers/namespaces/gems_controller_test.rb`
Expected: PASS — including the existing `push` test that asserts `version.created_by == users.plain` (polymorphic returns the `User` transparently).

- [ ] **Step 7: Commit**

```bash
jj commit -m "Make Version#created_by polymorphic

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 8: OIDC::TokenExchange service

**Files:**
- Create: `app/models/oidc/token_exchange.rb`
- Test: `test/models/oidc/token_exchange_test.rb`

**Interfaces:**
- Consumes: `OIDC::Provider#decode`, `TrustedPublisher#matches?`, `TrustedPublisher#push_keys`, `OIDC::IdToken`.
- Produces:
  - `OIDC::TokenExchange::Error < StandardError`.
  - `OIDC::TokenExchange.new(namespace:, jwt:, audience: Peak.host)`.
  - `#call -> TrustedPublisher::PushKey` (raises `OIDC::TokenExchange::Error` on any failure).
  - Behavior: decode unverified to read `iss`; `OIDC::Provider.for_issuer`; verified `decode`; find a single matching `TrustedPublisher` in the namespace; reject ambiguous matches and replays; mint a key; record `OIDC::IdToken`.

- [ ] **Step 1: Write the service**

Create `app/models/oidc/token_exchange.rb`:

```ruby
class OIDC::TokenExchange
  class Error < StandardError; end

  def initialize(namespace:, jwt:, audience: Peak.host)
    @namespace = namespace
    @jwt = jwt
    @audience = audience
  end

  def call
    provider = resolve_provider
    claims = verify(provider, @jwt)
    guard_replay!(provider, claims)
    publisher = match_publisher(claims)
    mint(provider, publisher, claims)
  end

  private
    def resolve_provider
      payload, = JWT.decode(@jwt, nil, false)
      OIDC::Provider.for_issuer(payload["iss"])
    rescue JWT::DecodeError, ActiveRecord::RecordNotFound
      raise Error, "Unknown or malformed token issuer"
    end

    def verify(provider, jwt)
      provider.decode(jwt, audience: @audience)
    rescue JWT::DecodeError => e
      raise Error, "Token verification failed: #{e.message}"
    end

    def guard_replay!(provider, claims)
      if OIDC::IdToken.exists?(provider:, jti: claims["jti"])
        raise Error, "Token has already been used"
      end
    end

    def match_publisher(claims)
      candidates = @namespace.trusted_publishers.select { _1.matches?(claims) }
      raise Error, "No trusted publisher matches this token" if candidates.empty?
      raise Error, "Token matches multiple trusted publishers" if candidates.size > 1
      candidates.first
    end

    def mint(provider, publisher, claims)
      key = nil
      OIDC::IdToken.transaction do
        key = publisher.push_keys.create!
        OIDC::IdToken.create!(provider:, trusted_publisher: publisher,
          push_key: key, jti: claims["jti"], claims:)
      end
      key
    end
end
```

> `@namespace.trusted_publishers` requires the association. Add to `app/models/namespace.rb`: `has_many :trusted_publishers, dependent: :destroy` (place beside `has_many :indexes`).

- [ ] **Step 2: Add the namespace association**

In `app/models/namespace.rb`, after `has_many :indexes, dependent: :destroy`, add:

```ruby
  has_many :trusted_publishers, dependent: :destroy
```

- [ ] **Step 3: Write the test**

Create `test/models/oidc/token_exchange_test.rb`:

```ruby
require "test_helper"

class OIDC::TokenExchangeTest < ActiveSupport::TestCase
  setup do
    stub_oidc_discovery
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  def exchange(jwt) = OIDC::TokenExchange.new(namespace: namespaces.gemcoop, jwt:).call

  test "mints a scoped key on a matching token" do
    key = exchange(build_github_jwt)
    assert_kind_of TrustedPublisher::PushKey, key
    assert_equal @publisher, key.trusted_publisher
    assert key.token.start_with?(TrustedPublisher::PushKey::PREFIX)
    assert_equal 1, OIDC::IdToken.count
  end

  test "raises when no publisher matches" do
    jwt = build_github_jwt(repository: "evil/peak", repository_owner: "evil")
    assert_raises(OIDC::TokenExchange::Error) { exchange(jwt) }
  end

  test "rejects a replayed jti" do
    jwt = build_github_jwt
    exchange(jwt)
    assert_raises(OIDC::TokenExchange::Error) { exchange(jwt) }
  end

  test "rejects ambiguous matches" do
    TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    assert_raises(OIDC::TokenExchange::Error) { exchange(build_github_jwt) }
  end

  test "rejects an unknown issuer" do
    jwt = JWT.encode(default_github_claims(iss: "https://evil.example"), oidc_rsa_key, "RS256")
    assert_raises(OIDC::TokenExchange::Error) { exchange(jwt) }
  end
end
```

- [ ] **Step 4: Run**

Run: `bin/rails test test/models/oidc/token_exchange_test.rb`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
jj commit -m "Add OIDC::TokenExchange service

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 9: Exchange endpoint

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/namespaces/oidc/exchanges_controller.rb`
- Test: `test/controllers/namespaces/oidc/exchanges_controller_test.rb`

**Interfaces:**
- Consumes: `OIDC::TokenExchange`, the `namespace_gem_push_url` route helper.
- Produces: `POST /:namespace/api/v1/oidc/trusted_publisher/exchange_token`; JSON request `{"jwt": "…"}`; JSON response `{rubygems_api_key, name, scopes, expires_at, namespace, push_url}` on success, `{error}` with 401 otherwise. Route helper `namespace_oidc_exchange_token_url`.

- [ ] **Step 1: Add the route**

In `config/routes.rb`, inside the `namespace :namespaces, path: "/:namespace(/:index)", as: :namespace do` block, immediately after the `post "/api/v1/gems", …` line, add:

```ruby
      post "/api/v1/oidc/trusted_publisher/exchange_token",
        to: "oidc/exchanges#create", as: :oidc_exchange_token
```

- [ ] **Step 2: Write the controller**

Create `app/controllers/namespaces/oidc/exchanges_controller.rb`:

```ruby
class Namespaces::Oidc::ExchangesController < Public::BaseController
  skip_forgery_protection

  rate_limit to: 10, within: 1.minute, with: :rate_limit_response, only: :create

  def create
    namespace = Namespace.approved.named(params[:namespace])
    key = OIDC::TokenExchange.new(namespace:, jwt: params.require(:jwt)).call

    render json: {
      rubygems_api_key: key.token,
      name: key.name,
      scopes: key.scopes,
      expires_at: key.expires_at.iso8601,
      namespace: namespace.name,
      push_url: namespace_gem_push_url(namespace: namespace.name)
    }
  rescue OIDC::TokenExchange::Error => e
    render json: { error: e.message }, status: :unauthorized
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Unknown namespace" }, status: :not_found
  rescue ActionController::ParameterMissing
    render json: { error: "Missing jwt parameter" }, status: :bad_request
  end

  private
    def rate_limit_response
      render json: { error: "Too many token exchange attempts. Try again later." },
        status: :too_many_requests
    end
end
```

- [ ] **Step 3: Write the integration test**

Create `test/controllers/namespaces/oidc/exchanges_controller_test.rb`:

```ruby
require "test_helper"

class Namespaces::Oidc::ExchangesControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.config.action_controller.cache_store.clear
    stub_oidc_discovery
    @publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  def url = namespace_oidc_exchange_token_url(namespace: namespaces.gemcoop.name)

  test "exchange returns a rubygems-compatible key" do
    post url, params: { jwt: build_github_jwt }
    assert_response :success

    body = JSON.parse(response.body)
    assert body["rubygems_api_key"].start_with?(TrustedPublisher::PushKey::PREFIX)
    assert_equal "trusted-publisher:peak", body["name"]
    assert_equal %w[push_rubygem], body["scopes"]
    assert_equal "@gemcoop", body["namespace"]
    assert_includes body["push_url"], "/@gemcoop/api/v1/gems"
  end

  test "non-matching token is unauthorized" do
    post url, params: { jwt: build_github_jwt(repository: "evil/peak", repository_owner: "evil") }
    assert_response :unauthorized
    assert_equal "No trusted publisher matches this token", JSON.parse(response.body)["error"]
  end

  test "missing jwt is a bad request" do
    post url
    assert_response :bad_request
  end
end
```

- [ ] **Step 4: Run**

Run: `bin/rails test test/controllers/namespaces/oidc/exchanges_controller_test.rb`
Expected: PASS. If routing fails to resolve the `oidc/exchanges` controller, confirm the file is at `app/controllers/namespaces/oidc/exchanges_controller.rb` and the class is `Namespaces::Oidc::ExchangesController`.

- [ ] **Step 5: Commit**

```bash
jj commit -m "Add trusted publisher token exchange endpoint

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 10: Push authentication dispatch and scoping

**Files:**
- Modify: `app/controllers/namespaces/gems_controller.rb`
- Test: `test/controllers/namespaces/gems_controller_test.rb`

**Interfaces:**
- Consumes: `TrustedPublisher::PushKey`, `User::PushKey`, `TrustedPublisher#target_index`, `TrustedPublisher#link_gem!`.
- Produces: `#create` authenticates by token prefix. TP keys: route to `publisher.target_index`, enforce URL namespace == publisher namespace and `upload.name == gem_name`, attribute `created_by = publisher`, convert pending publisher on success. User keys: unchanged path, `created_by = user`.

- [ ] **Step 1: Rewrite the controller**

Replace `app/controllers/namespaces/gems_controller.rb` with:

```ruby
class Namespaces::GemsController < Public::BaseController
  skip_forgery_protection only: :create
  before_action :authenticate_push, only: :create

  def create
    upload = Current.upload_from(request.body)

    if @trusted_publisher && upload.name != @trusted_publisher.gem_name
      return render plain: "Token is scoped to #{@trusted_publisher.gem_name}, not #{upload.name}. ❌",
        status: :forbidden
    end

    version = @index.gems.version_from name: upload.name, ref: upload.platform_ref

    if version.persisted?
      render plain: "Upload skipped: #{version.package_name} already exists. ❌", status: :conflict
    else
      version.process upload, created_by: @actor
      @trusted_publisher&.link_gem!(version.gem)

      render plain: "#{version.package_name} uploaded 🎉"
    end
  end

  def show
    set_routed_index

    gem_name, ref = Peak::Gem.version(params[:id])
    version = @index.versions.for(gem_name).find_by!(ref:)

    if version.package.attached?
      expires_in 1.year, public: @index.public_access?

      send_data version.package.download, filename: version.package_name, disposition: "inline"
    else
      redirect_to "https://gem.coop/gems/#{params[:id]}", allow_other_host: true
    end
  end

  private
    def authenticate_push
      token = request.authorization.to_s.delete_prefix("Bearer ")
      if token.start_with?(TrustedPublisher::PushKey::PREFIX)
        authenticate_by_trusted_publisher(token)
      else
        authenticate_index_by_user_push_key(token)
      end
    end

    def authenticate_by_trusted_publisher(token)
      key = TrustedPublisher::PushKey.active.find_by!(token:)
      @trusted_publisher = key.trusted_publisher
      @actor = @trusted_publisher

      if @trusted_publisher.namespace.name != params[:namespace]
        return render plain: "Token is not valid for #{params[:namespace]}. ❌", status: :unauthorized
      end

      @index = @trusted_publisher.target_index
    rescue ActiveRecord::RecordNotFound
      render plain: "API Key is either incorrect or doesn't exist", status: :unauthorized
    end

    def authenticate_index_by_user_push_key(token)
      @actor = User::PushKey.active.find_by!(token:).user
      set_routed_index from: @actor.namespaces
    rescue ActiveRecord::RecordNotFound
      if @actor
        render plain: "User doesn't have access to the given namespace", status: :unauthorized
      else
        render plain: "API Key is either incorrect or doesn't exist", status: :unauthorized
      end
    end
end
```

> Note: `@actor` replaces the old `@user`. The user path still sets `@actor` to the `User`, so `created_by: @actor` is identical to before for human pushes.

- [ ] **Step 2: Add TP-push integration tests**

Append to `test/controllers/namespaces/gems_controller_test.rb` (inside the class):

```ruby
  def tp_publisher(gem: gems.peak, gem_name: "peak")
    TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem:, gem_name:,
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
  end

  test "push with a trusted publisher key attributes to the publisher" do
    publisher = tp_publisher
    key = publisher.push_keys.create!
    package = file_fixture "peak/peak-0.2.0.gem"

    assert_increments gems.peak.versions do
      post namespace_gem_push_url(namespace: namespaces.gemcoop),
        env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{key.token}" }
    end
    assert_response :success

    version = versions.by gems.peak, ref: "0.2.0"
    assert_equal publisher, version.created_by
  end

  test "trusted publisher key cannot push another gem" do
    publisher = tp_publisher(gem: gems.oaken, gem_name: "oaken")
    key = publisher.push_keys.create!
    package = file_fixture "peak/peak-0.2.0.gem"

    post namespace_gem_push_url(namespace: namespaces.gemcoop),
      env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{key.token}" }
    assert_response :forbidden
  end

  test "pending publisher converts on first push" do
    publisher = tp_publisher(gem: nil)
    key = publisher.push_keys.create!
    package = file_fixture "peak/peak-0.2.0.gem"

    post namespace_gem_push_url(namespace: namespaces.gemcoop),
      env: { "RAW_POST_DATA" => package.binread, authorization: "Bearer #{key.token}" }
    assert_response :success

    assert_equal gems.peak, publisher.reload.gem
    assert_not publisher.pending?
  end
```

> `gems.oaken` exists in the `@gemcoop` seed (`_1.parse :oaken, …`). Confirm with `bin/rails runner 'p Oaken' ` is unnecessary; the seed file shows it.

- [ ] **Step 3: Run**

Run: `bin/rails test test/controllers/namespaces/gems_controller_test.rb`
Expected: PASS — including the pre-existing `push` and `push platform` tests (user-key path unchanged).

- [ ] **Step 4: Commit**

```bash
jj commit -m "Dispatch push auth by token prefix and scope TP pushes

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 11: Namespace owner authorization concern

**Files:**
- Create: `app/controllers/concerns/namespace_authorization.rb`
- Test: `test/controllers/concerns/namespace_authorization_test.rb` (via a host controller in Task 12; this task only adds the concern + a unit-ish test)

**Interfaces:**
- Consumes: `Authentication` (`require_authentication`, `Current.user`), `Namespace`, `Namespace::Access`.
- Produces: `NamespaceAuthorization` concern with `before_action`-friendly `require_namespace_owner` and helper `current_namespace` (memoized, looked up by `params[:namespace]`). Sets `@namespace`. Redirects non-owners to the namespace profile with an alert.

- [ ] **Step 1: Write the concern**

Create `app/controllers/concerns/namespace_authorization.rb`:

```ruby
module NamespaceAuthorization
  extend ActiveSupport::Concern

  included do
    include Authentication
    require_authentication
    before_action :require_namespace_owner
  end

  private
    def current_namespace
      @namespace ||= Namespace.approved.named(params[:namespace])
    end

    def require_namespace_owner
      unless current_namespace.accesses.owner.exists?(user: Current.user)
        redirect_to public_namespace_path(current_namespace.name),
          alert: "You must be an owner of #{current_namespace.name} to manage trusted publishers."
      end
    end
end
```

> `Namespace::Access` already defines `enum :role, %i[plain owner]…`, providing the `owner` scope. Confirm the profile route name: `config/routes.rb` defines `get "/:namespace", … as: :namespace` inside the constrained block (helper `namespace_path`) and a separate `get "/:namespace", to: "namespaces/profiles#show", as: :namespace` — verify the exact helper name with `bin/rails routes -g namespace | grep profiles` and use that helper. If it is `namespace_path`, replace `public_namespace_path(current_namespace.name)` with `namespace_path(current_namespace.name)`.

- [ ] **Step 2: Verify the redirect target route helper**

Run: `bin/rails routes -c namespaces/profiles`
Expected: shows the profile route; note its prefix (e.g. `namespace`). Update the concern's redirect helper to match if needed.

- [ ] **Step 3: Commit**

```bash
jj commit -m "Add NamespaceAuthorization owner gate concern

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 12: Gem-scoped trusted publishers UI

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/namespaces/gems/trusted_publishers_controller.rb`
- Create: `app/views/namespaces/gems/trusted_publishers/index.html.erb`
- Create: `app/views/namespaces/gems/trusted_publishers/_form.html.erb`
- Test: `test/controllers/namespaces/gems/trusted_publishers_controller_test.rb`

**Interfaces:**
- Consumes: `NamespaceAuthorization`, `Namespace::Gem`, `TrustedPublisher::GitHubActions`, `oidc_providers.github`.
- Produces: routes `namespace_gem_trusted_publishers` (index, create) and `namespace_gem_trusted_publisher` (destroy), nested under the gem. Index lists this gem's publishers and a creation form; create/destroy gated to owners.

- [ ] **Step 1: Add routes**

In `config/routes.rb`, inside the same constrained `namespace :namespaces, path: "/:namespace(/:index)", as: :namespace do` block, after `get "/:id", to: "gems/profiles#show", as: :gem`, add:

```ruby
      scope path: "/:gem_id", as: :gem do
        resources :trusted_publishers, only: %i[index create destroy], module: :gems
      end
```

> This yields `namespace_gem_trusted_publishers_path(namespace:, gem_id:)` etc., handled by `Namespaces::Gems::TrustedPublishersController`. Run `bin/rails routes -g trusted_publishers` after editing to confirm the exact helper names and adjust the views/tests to match.

- [ ] **Step 2: Write the controller**

Create `app/controllers/namespaces/gems/trusted_publishers_controller.rb`:

```ruby
class Namespaces::Gems::TrustedPublishersController < ApplicationController
  include NamespaceAuthorization

  before_action :set_gem

  def index
    @trusted_publishers = @gem.trusted_publishers.order(:created_at)
    @trusted_publisher = TrustedPublisher::GitHubActions.new
  end

  def create
    @trusted_publisher = @gem.trusted_publishers.build(
      trusted_publisher_params.merge(
        type: "TrustedPublisher::GitHubActions",
        namespace: current_namespace,
        gem_name: @gem.name,
        provider: OIDC::Provider::GitHubActions.sole))

    if @trusted_publisher.save
      redirect_to namespace_gem_trusted_publishers_path(namespace: current_namespace.name, gem_id: @gem.name),
        notice: "Trusted publisher added."
    else
      @trusted_publishers = @gem.trusted_publishers.order(:created_at)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    @gem.trusted_publishers.find(params[:id]).destroy!
    redirect_to namespace_gem_trusted_publishers_path(namespace: current_namespace.name, gem_id: @gem.name),
      notice: "Trusted publisher removed."
  end

  private
    def set_gem
      @gem = current_namespace.default_index.gems.named(params[:gem_id])
    end

    def trusted_publisher_params
      params.require(:trusted_publisher).permit(
        :repository_owner, :repository_name, :workflow_filename, :environment, :ref)
    end
end
```

> Requires `Namespace::Gem` to expose `has_many :trusted_publishers`. Add to `app/models/namespace/gem.rb` (beside its other `has_many`): `has_many :trusted_publishers, dependent: :destroy`. `OIDC::Provider::GitHubActions.sole` returns the single seeded row (raises if zero/many — acceptable, the provider is always seeded).

- [ ] **Step 3: Add the gem association**

In `app/models/namespace/gem.rb`, after `has_many :versions, dependent: :destroy`, add:

```ruby
  has_many :trusted_publishers, dependent: :destroy
```

- [ ] **Step 4: Write the views**

Create `app/views/namespaces/gems/trusted_publishers/index.html.erb`:

```erb
<% page.title = "Trusted Publishers · #{@gem.name}" %>

<h1>Trusted Publishers for <%= @gem.name %></h1>

<p>Trusted publishers let GitHub Actions push <%= @gem.name %> without a stored API key.</p>

<% if @trusted_publishers.any? %>
  <ul>
    <% @trusted_publishers.each do |publisher| %>
      <li>
        <code><%= publisher.repository_owner %>/<%= publisher.repository_name %></code>
        — <%= publisher.workflow_filename %>
        <%= " (env: #{publisher.environment})" if publisher.environment.present? %>
        <%= button_to "Remove",
          namespace_gem_trusted_publisher_path(namespace: @gem.namespace.name, gem_id: @gem.name, id: publisher.id),
          method: :delete %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No trusted publishers yet.</p>
<% end %>

<h2>Add a GitHub Actions publisher</h2>
<%= render "form", trusted_publisher: @trusted_publisher, gem: @gem %>
```

Create `app/views/namespaces/gems/trusted_publishers/_form.html.erb`:

```erb
<%= form_with model: trusted_publisher,
      url: namespace_gem_trusted_publishers_path(namespace: gem.namespace.name, gem_id: gem.name),
      scope: :trusted_publisher do |form| %>
  <% if trusted_publisher.errors.any? %>
    <ul>
      <% trusted_publisher.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  <% end %>

  <%= form.label :repository_owner, "Repository owner" %>
  <%= form.text_field :repository_owner, placeholder: "gem-coop" %>

  <%= form.label :repository_name, "Repository name" %>
  <%= form.text_field :repository_name, placeholder: "peak" %>

  <%= form.label :workflow_filename, "Workflow filename" %>
  <%= form.text_field :workflow_filename, placeholder: "release.yml" %>

  <%= form.label :environment, "Environment (optional)" %>
  <%= form.text_field :environment %>

  <%= form.button "Add trusted publisher" %>
<% end %>
```

- [ ] **Step 5: Write the test**

Create `test/controllers/namespaces/gems/trusted_publishers_controller_test.rb`:

```ruby
require "test_helper"

class Namespaces::Gems::TrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  def index_url = namespace_gem_trusted_publishers_url(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name)
  def valid_params
    { trusted_publisher: { repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml" } }
  end

  test "owner can create a trusted publisher" do
    sign_in_as users.owner
    assert_increments gems.peak.trusted_publishers do
      post index_url, params: valid_params
    end
    assert_response :redirect
    assert_equal "TrustedPublisher::GitHubActions", gems.peak.trusted_publishers.last.type
  end

  test "non-owner is redirected" do
    sign_in_as users.plain
    refute_increments gems.peak.trusted_publishers do
      post index_url, params: valid_params
    end
    assert_response :redirect
  end

  test "unauthenticated is redirected to sign in" do
    post index_url, params: valid_params
    assert_response :redirect
  end

  test "owner can list" do
    sign_in_as users.owner
    get index_url
    assert_response :success
  end
end
```

- [ ] **Step 6: Run**

Run: `bin/rails test test/controllers/namespaces/gems/trusted_publishers_controller_test.rb`
Expected: PASS. If route helpers differ from the names used here, reconcile with `bin/rails routes -g trusted_publishers` output (the source of truth) and update both views and test.

- [ ] **Step 7: Commit**

```bash
jj commit -m "Add gem-scoped trusted publisher management UI

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 13: Pending trusted publishers UI (namespace level)

**Files:**
- Modify: `config/routes.rb`
- Create: `app/controllers/namespaces/trusted_publishers_controller.rb`
- Create: `app/views/namespaces/trusted_publishers/index.html.erb`
- Create: `app/views/namespaces/trusted_publishers/_form.html.erb`
- Test: `test/controllers/namespaces/trusted_publishers_controller_test.rb`

**Interfaces:**
- Consumes: `NamespaceAuthorization`, `Namespace#trusted_publishers`, `TrustedPublisher.pending` scope.
- Produces: routes `namespace_trusted_publishers` (index, create) and `namespace_trusted_publisher` (destroy) under the namespace; index lists pending publishers + a form that takes a reserved `gem_name`.

- [ ] **Step 1: Add routes**

In `config/routes.rb`, inside the constrained `namespace :namespaces, path: "/:namespace(/:index)", as: :namespace do` block, before the gem catch-all `get "/:id", …`, add:

```ruby
      resources :trusted_publishers, only: %i[index create destroy]
```

> Place this **above** `get "/:id", to: "gems/profiles#show", as: :gem` so `/@ns/trusted_publishers` is not captured by the gem show route. Confirm ordering with `bin/rails routes -g trusted_publishers`.

- [ ] **Step 2: Write the controller**

Create `app/controllers/namespaces/trusted_publishers_controller.rb`:

```ruby
class Namespaces::TrustedPublishersController < ApplicationController
  include NamespaceAuthorization

  def index
    @trusted_publishers = current_namespace.trusted_publishers.pending.order(:created_at)
    @trusted_publisher = TrustedPublisher::GitHubActions.new
  end

  def create
    @trusted_publisher = current_namespace.trusted_publishers.build(
      trusted_publisher_params.merge(
        type: "TrustedPublisher::GitHubActions",
        provider: OIDC::Provider::GitHubActions.sole))

    if @trusted_publisher.save
      redirect_to namespace_trusted_publishers_path(namespace: current_namespace.name),
        notice: "Pending trusted publisher added."
    else
      @trusted_publishers = current_namespace.trusted_publishers.pending.order(:created_at)
      render :index, status: :unprocessable_entity
    end
  end

  def destroy
    current_namespace.trusted_publishers.pending.find(params[:id]).destroy!
    redirect_to namespace_trusted_publishers_path(namespace: current_namespace.name),
      notice: "Pending trusted publisher removed."
  end

  private
    def trusted_publisher_params
      params.require(:trusted_publisher).permit(
        :gem_name, :repository_owner, :repository_name, :workflow_filename, :environment, :ref)
    end
end
```

- [ ] **Step 3: Write the views**

Create `app/views/namespaces/trusted_publishers/index.html.erb`:

```erb
<% page.title = "Pending Trusted Publishers · #{current_namespace.name}" %>

<h1>Pending Trusted Publishers for <%= current_namespace.name %></h1>

<p>Reserve a gem name so GitHub Actions can publish it for the first time without an API key.</p>

<% if @trusted_publishers.any? %>
  <ul>
    <% @trusted_publishers.each do |publisher| %>
      <li>
        <strong><%= publisher.gem_name %></strong> —
        <code><%= publisher.repository_owner %>/<%= publisher.repository_name %></code>
        (<%= publisher.workflow_filename %>)
        <%= button_to "Remove",
          namespace_trusted_publisher_path(namespace: current_namespace.name, id: publisher.id),
          method: :delete %>
      </li>
    <% end %>
  </ul>
<% else %>
  <p>No pending trusted publishers.</p>
<% end %>

<h2>Reserve a gem name</h2>
<%= render "form", trusted_publisher: @trusted_publisher %>
```

Create `app/views/namespaces/trusted_publishers/_form.html.erb`:

```erb
<%= form_with model: trusted_publisher,
      url: namespace_trusted_publishers_path(namespace: current_namespace.name),
      scope: :trusted_publisher do |form| %>
  <% if trusted_publisher.errors.any? %>
    <ul>
      <% trusted_publisher.errors.full_messages.each do |message| %>
        <li><%= message %></li>
      <% end %>
    </ul>
  <% end %>

  <%= form.label :gem_name, "Gem name to reserve" %>
  <%= form.text_field :gem_name %>

  <%= form.label :repository_owner, "Repository owner" %>
  <%= form.text_field :repository_owner, placeholder: "gem-coop" %>

  <%= form.label :repository_name, "Repository name" %>
  <%= form.text_field :repository_name, placeholder: "peak" %>

  <%= form.label :workflow_filename, "Workflow filename" %>
  <%= form.text_field :workflow_filename, placeholder: "release.yml" %>

  <%= form.label :environment, "Environment (optional)" %>
  <%= form.text_field :environment %>

  <%= form.button "Reserve" %>
<% end %>
```

- [ ] **Step 4: Write the test**

Create `test/controllers/namespaces/trusted_publishers_controller_test.rb`:

```ruby
require "test_helper"

class Namespaces::TrustedPublishersControllerTest < ActionDispatch::IntegrationTest
  def index_url = namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
  def valid_params
    { trusted_publisher: { gem_name: "brand_new_gem", repository_owner: "gem-coop",
        repository_name: "brand_new_gem", workflow_filename: "release.yml" } }
  end

  test "owner can reserve a pending publisher" do
    sign_in_as users.owner
    assert_increments namespaces.gemcoop.trusted_publishers do
      post index_url, params: valid_params
    end
    publisher = namespaces.gemcoop.trusted_publishers.order(:created_at).last
    assert publisher.pending?
    assert_equal "brand_new_gem", publisher.gem_name
  end

  test "non-owner is redirected" do
    sign_in_as users.plain
    refute_increments namespaces.gemcoop.trusted_publishers do
      post index_url, params: valid_params
    end
    assert_response :redirect
  end

  test "owner can list pending publishers" do
    sign_in_as users.owner
    get index_url
    assert_response :success
  end
end
```

- [ ] **Step 5: Run**

Run: `bin/rails test test/controllers/namespaces/trusted_publishers_controller_test.rb`
Expected: PASS. Reconcile any helper-name mismatches against `bin/rails routes -g trusted_publishers`.

- [ ] **Step 6: Commit**

```bash
jj commit -m "Add pending trusted publisher management UI

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 14: Avo admin resources

**Files:**
- Create: `app/avo/resources/trusted_publisher.rb`
- Create: `app/avo/resources/oidc_provider.rb`
- Create: `app/avo/resources/oidc_id_token.rb`
- Create: `app/avo/resources/trusted_publisher_push_key.rb`
- Create: `app/controllers/avo/trusted_publishers_controller.rb`
- Create: `app/controllers/avo/oidc_providers_controller.rb`
- Create: `app/controllers/avo/oidc_id_tokens_controller.rb`
- Create: `app/controllers/avo/trusted_publisher_push_keys_controller.rb`
- Test: `test/integration/avo_trusted_publishing_test.rb`

**Interfaces:**
- Consumes: the four models. Avo resources are auto-discovered; each declares `self.model_class`.
- Produces: Avo index/show/forms for trusted publishers (with a `Pending` scope), providers, id tokens (read-only audit), and minted push keys.

- [ ] **Step 1: Add a Pending Avo scope**

Create `app/avo/scopes/pending_publishers.rb`:

```ruby
class Avo::Scopes::PendingPublishers < Avo::Advanced::Scopes::BaseScope
  self.name = "Pending"
  self.description = "Publishers reserving a not-yet-existing gem"
  self.scope = :pending
  self.visible = -> { true }
end
```

- [ ] **Step 2: Write the resources**

Create `app/avo/resources/trusted_publisher.rb`:

```ruby
class Avo::Resources::TrustedPublisher < Avo::BaseResource
  self.model_class = ::TrustedPublisher

  def scopes
    scope Avo::Scopes::PendingPublishers
  end

  def fields
    field :id, as: :id
    field :type, as: :text
    field :gem_name, as: :text
    field :namespace, as: :belongs_to
    field :gem, as: :belongs_to
    field :provider, as: :belongs_to
    field :repository_owner, as: :text
    field :repository_name, as: :text
    field :workflow_filename, as: :text
    field :environment, as: :text
    field :ref, as: :text
    field :created_at, as: :date_time, hide_on: :forms
  end
end
```

Create `app/avo/resources/oidc_provider.rb`:

```ruby
class Avo::Resources::OidcProvider < Avo::BaseResource
  self.model_class = ::OIDC::Provider

  def fields
    field :id, as: :id
    field :type, as: :text
    field :name, as: :text
    field :issuer, as: :text
    field :trusted_publishers, as: :has_many
  end
end
```

Create `app/avo/resources/oidc_id_token.rb`:

```ruby
class Avo::Resources::OidcIdToken < Avo::BaseResource
  self.model_class = ::OIDC::IdToken

  def fields
    field :id, as: :id
    field :jti, as: :text
    field :provider, as: :belongs_to
    field :trusted_publisher, as: :belongs_to
    field :push_key, as: :belongs_to
    field :claims, as: :code, language: "json"
    field :created_at, as: :date_time
  end
end
```

Create `app/avo/resources/trusted_publisher_push_key.rb`:

```ruby
class Avo::Resources::TrustedPublisherPushKey < Avo::BaseResource
  self.model_class = ::TrustedPublisher::PushKey

  def fields
    field :id, as: :id
    field :trusted_publisher, as: :belongs_to
    field :name, as: :text, only_on: :show
    field :expires_at, as: :date_time
    field :created_at, as: :date_time, hide_on: :forms
  end
end
```

- [ ] **Step 3: Write the Avo controllers**

Create each of these (mirroring `app/controllers/avo/user_push_keys_controller.rb`):

`app/controllers/avo/trusted_publishers_controller.rb`:
```ruby
class Avo::TrustedPublishersController < Avo::ResourcesController
end
```

`app/controllers/avo/oidc_providers_controller.rb`:
```ruby
class Avo::OidcProvidersController < Avo::ResourcesController
end
```

`app/controllers/avo/oidc_id_tokens_controller.rb`:
```ruby
class Avo::OidcIdTokensController < Avo::ResourcesController
end
```

`app/controllers/avo/trusted_publisher_push_keys_controller.rb`:
```ruby
class Avo::TrustedPublisherPushKeysController < Avo::ResourcesController
end
```

- [ ] **Step 4: Write a smoke test**

Create `test/integration/avo_trusted_publishing_test.rb`:

```ruby
require "test_helper"

class AvoTrustedPublishingTest < ActionDispatch::IntegrationTest
  # Avo is only mounted when the :avo bundler group is loaded (Peak.avo?).
  setup { skip "Avo not loaded" unless Peak.avo? }

  def auth = { "HTTP_AUTHORIZATION" => ActionController::HttpAuthentication::Basic.encode_credentials(*avo_credentials) }
  def avo_credentials = [ENV.fetch("ADMIN_USERNAME", "gem-coop"), ENV.fetch("ADMIN_PASSWORD", "")]

  test "trusted publishers index renders" do
    get "/avo/resources/trusted_publishers", headers: auth
    assert_includes [200, 302], response.status
  end
end
```

> This is a light smoke test; Avo admin behavior is covered by Avo itself. If Avo basic-auth is awkward to satisfy in test, leave the `skip` guard and rely on manual verification (Step 5).

- [ ] **Step 5: Manual verification**

Run: `bin/dev` (or `bin/rails server` with the `avo` group), sign into `/avo`, and confirm the four resources appear and the `Pending` scope filters trusted publishers.

- [ ] **Step 6: Run the smoke test**

Run: `bin/rails test test/integration/avo_trusted_publishing_test.rb`
Expected: PASS or skipped.

- [ ] **Step 7: Commit**

```bash
jj commit -m "Add Avo admin resources for trusted publishing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 15: Production provider bootstrap, docs, and full suite

**Files:**
- Create: `db/migrate/20260619000006_seed_github_actions_provider.rb`
- Modify: `docs/DEVELOPMENT.md` (append a short section) or create `docs/trusted-publishing.md`
- Test: full suite

**Interfaces:**
- Consumes: `OIDC::Provider::GitHubActions`.
- Produces: a data migration that ensures the GitHub Actions provider row exists in every environment (the Oaken seed only covers seeded/test/dev databases).

- [ ] **Step 1: Write the data migration**

Create `db/migrate/20260619000006_seed_github_actions_provider.rb`:

```ruby
class SeedGithubActionsProvider < ActiveRecord::Migration[8.1]
  def up
    OIDC::Provider::GitHubActions.create_or_find_by!(
      issuer: OIDC::Provider::GitHubActions::ISSUER
    ) { _1.name = "GitHub Actions" }
  end

  def down
    OIDC::Provider::GitHubActions.where(issuer: OIDC::Provider::GitHubActions::ISSUER).delete_all
  end
end
```

- [ ] **Step 2: Migrate**

Run: `bin/rails db:migrate`
Expected: provider row present (`OIDC::Provider.count >= 1`).

- [ ] **Step 3: Document the feature**

Append to `docs/DEVELOPMENT.md` a "Trusted Publishing" section describing: the exchange endpoint (`POST /:namespace/api/v1/oidc/trusted_publisher/exchange_token`, body `{"jwt":"…"}`), the rubygems-compatible response, the GitHub Actions `id-token: write` requirement, that the client's `RUBYGEMS_HOST`/gem source must include the namespace (e.g. `https://gem.coop/@your-namespace`) so exchange and push stay relative siblings, and how to configure gem-scoped vs pending publishers in the UI.

- [ ] **Step 4: Run the full suite**

Run: `bin/rails test`
Expected: all green. Investigate and fix any regressions (especially the existing gems controller and version tests).

- [ ] **Step 5: Run linters**

Run: `bin/rubocop` and `bin/brakeman --no-pager` (per the repo's CI). Fix style/security findings introduced by the new code.

- [ ] **Step 6: Commit**

```bash
jj commit -m "Seed GitHub Actions provider and document trusted publishing

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Pluggable provider registry, GitHub first → Tasks 1, 2, 15.
- Gem-scoped + pending publishers → Tasks 3 (`pending?`, `link_gem!`), 12, 13.
- TP mints short-lived push tokens, distinct prefix → Tasks 4, 5.
- Polymorphic attribution → Task 7, exercised in Task 10.
- rubygems-compatible exchange under `/:namespace`, returns namespace/push_url → Tasks 8, 9.
- Push path dispatch + scope enforcement + pending conversion → Task 10.
- UI on gem page + namespace for pending, owner-gated → Tasks 11, 12, 13.
- Avo resources (publishers, providers, id tokens, push keys) → Task 14.
- Security: RS256, aud=host, exp/nbf/iat, jti replay, ambiguous-match reject, short TTL, exchange rate limit, owner-only management → Tasks 2, 5, 8, 9, 11.
- Testing: unit (2,3,5,6,7,8), integration (9,10,12,13), Avo smoke (14) → covered.

**Placeholder scan:** No TBD/TODO left in steps; every code step shows full code. The only deferred items are explicit route-helper reconciliations (`bin/rails routes …`), which are verification steps, not placeholders.

**Type consistency:** `@actor` used consistently in Task 10; `TrustedPublisher::PushKey::PREFIX` referenced identically across Tasks 5/8/9/10; `OIDC::Provider#decode(jwt, audience:)` signature consistent between Tasks 2 and 8; `matches?(claims)` consistent between Tasks 3 and 8; `target_index`/`link_gem!`/`gem_name` consistent across 3/5/10.

**Known reconciliation points (call out during execution, not blockers):** exact route-helper names for the profile redirect (Task 11) and the nested/namespace trusted-publisher routes (Tasks 12, 13) must be confirmed with `bin/rails routes` and the views/tests aligned to the generated helpers.
