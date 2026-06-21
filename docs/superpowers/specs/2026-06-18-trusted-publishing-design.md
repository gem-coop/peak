# Trusted Publishing — Design

Date: 2026-06-18
Status: Approved (pending implementation plan)

## Summary

Add trusted publishing to Peak: CI systems present a short-lived OIDC JWT, the
server matches it against a preconfigured, gem-scoped trusted-publisher record,
and mints a short-lived, scoped push token instead of requiring a stored secret.
This complements (does not replace) the existing email-minted `User::PushKey`.

The exchange contract matches rubygems.org's so stock tooling (`gem`,
`configure-rubygems-credentials`) works, but the endpoint is mounted under
Peak's `/:namespace` scope so the exchange and push routes stay relative
siblings under the client's configured host.

## Decisions

- **Scope of credential work:** trusted publishing mints short-lived push
  tokens only. No separate long-lived, user-managed API key system.
- **Binding:** gem-scoped, with *pending* publishers that reserve a gem name
  that does not yet exist and convert on first push.
- **Providers:** a pluggable provider registry; GitHub Actions is the only
  concrete provider implemented now.
- **Credential type:** a dedicated `TrustedPublisher::PushKey` class with a
  distinct token prefix, rather than overloading `User::PushKey` with a
  polymorphic owner. Keeps each table's ownership column non-nullable.
- **Attribution:** `Namespace::Gem::Version#created_by` becomes polymorphic — a
  push is "by" a `User` or a `TrustedPublisher`.
- **API compatibility:** rubygems-compatible exchange contract, mounted under
  `/:namespace`, with the namespace/push URL added to the response.
- **UI home:** gem-scoped publishers managed on the gem profile page; pending
  publishers managed at the namespace level. Both owner-gated.

## Background — current state

- **Push auth today:** `User::PushKey` is a 24h bearer token minted by an email
  magic link (`POST /user/push_keys`). It is used as `Authorization: Bearer …`
  against `POST /:namespace/api/v1/gems`
  (`Namespaces::GemsController#create`). `authenticate_index_by_user_push_key`
  resolves the token to a `User`, then routes to one of that user's namespaces.
- **Ownership:** `Namespace` → `Namespace::Access` (role `plain`/`owner`) →
  `User`. Gems live under `Namespace::Index` under `Namespace`; gems are
  auto-created on first push via `find_or_create_by!`.
- **Attribution:** `Namespace::Gem::Version` `belongs_to :created_by,
  class_name: "User"` (`created_by_id` is `null: false`). `as_byline` includes
  `created_by` for rendering.
- No JWT/OIDC infrastructure exists yet; `jwt` is not in the lockfile.

## Reference — rubygems.org exchange contract

- `POST /api/v1/oidc/trusted_publisher/exchange_token`
- Request body: `{"jwt": "<id token>"}`
- Response fields: `rubygems_api_key`, `name`, `scopes`, `expires_at`
- GitHub Actions claims matched: `repository`, `repository_owner`,
  `workflow_ref` (workflow filename), `environment`, `ref`. Standard claims:
  `iss`, `aud`, `iat`, `exp`, `nbf`, `jti`.

Sources: [RubyGems trusted publishing guide](https://guides.rubygems.org/trusted-publishing/),
[configure-rubygems-credentials](https://github.com/rubygems/configure-rubygems-credentials),
[RubyGems OIDC RFC 0010](https://github.com/rubygems/rfcs/blob/master/text/0010-OIDC.md).

## Data model

### New models

**`OIDC::Provider`** — the pluggable issuer registry.

- Columns: `issuer` (e.g. `https://token.actions.githubusercontent.com`),
  `name`, and a JWKS source discovered via
  `<issuer>/.well-known/openid-configuration` (keys cached, with rotation).
- Concrete per-provider behavior (which claims identify an identity, how to
  normalize them) lives in an STI/handler subclass; the base handles signature
  and standard-claim verification. `OIDC::Provider::GitHubActions` is the only
  subclass implemented now.

**`TrustedPublisher`** (STI base; `TrustedPublisher::GitHubActions` concrete) —
one row per trusted configuration.

- `belongs_to :namespace`
- `belongs_to :gem` (optional, `Namespace::Gem`)
- `gem_name` (always set — the reserved name)
- `belongs_to :provider` (`OIDC::Provider`)
- `pending?` ⟺ `gem.nil?`. On first successful push the gem is auto-created and
  the publisher links to it (`gem_id` set, `gem_name` retained).
- Target index resolution: `gem&.index || namespace.default_index`.
- Claim policy as typed columns on the subtype: `repository_owner`,
  `repository`, `workflow_ref`, optional `environment`, optional `ref`. The
  subclass declares which are required vs. optional.

**`TrustedPublisher::PushKey`** (table `trusted_publisher_push_keys`) — the
minted credential.

- `belongs_to :trusted_publisher`
- `expires_at` with a short TTL (15–30 min; configurable)
- `token` via `has_secure_token`, written with a distinct prefix
  (e.g. `gemcoop_tp_…`) — disambiguates credential type at the auth boundary and
  aids GitHub secret scanning.
- Scope is *implied* by the publisher (target index + `gem_name`); no separate
  scope columns.
- A shared `PushKey` concern extracts `active`/`expired?`/token lookup shared
  with `User::PushKey`.

**`OIDC::IdToken`** — audit record of each accepted exchange: `jti`, decoded
claims (JSON), matched `trusted_publisher`, and the minted push key. The unique
`jti` (per provider) doubles as replay protection.

### Changed models

**`Namespace::Gem::Version#created_by` → polymorphic** (`User` or
`TrustedPublisher`). Migration adds `created_by_type`, backfills existing rows
to `"User"`. `as_byline` and byline views render either actor.

`User::PushKey` is left untouched (other than extracting the shared `PushKey`
concern).

## Exchange flow

`OIDC::TokenExchange` service, invoked by
`POST /:namespace/api/v1/oidc/trusted_publisher/exchange_token`,
body `{"jwt": "<id token>"}`:

1. Decode the JWT header → `kid`; find `OIDC::Provider` by `iss`.
2. Verify the signature against the cached JWKS (RS256 only) and standard
   claims: `aud` bound to the Peak host, `exp`/`nbf`/`iat`, fresh `jti`.
3. Map provider claims → identity; find a `TrustedPublisher` **in the URL's
   namespace** whose policy matches. An ambiguous multi-match is rejected.
4. Mint a scoped `TrustedPublisher::PushKey` for the matched publisher; record
   an `OIDC::IdToken`.
5. Respond rubygems-compatible plus namespace/push URL:
   `{rubygems_api_key, name, scopes, expires_at, namespace, push_url}`.
   Because the endpoint is under `/:namespace`, the client's configured host
   already carries the namespace, so `exchange_token` and `gems` stay relative
   siblings.

## Push authentication

Generalize `authenticate_index_by_user_push_key` in
`Namespaces::GemsController` to dispatch on the bearer token's prefix:

- **TP prefix** → find the active `TrustedPublisher::PushKey`; resolve its
  publisher → target index + `gem_name`. Set the routed index to the
  publisher's index; enforce that the URL namespace matches the publisher's
  namespace; enforce `upload.name == gem_name` (a TP key can push only its one
  gem). `created_by = publisher`. For a pending publisher, the push creates the
  gem under the namespace's default index and the publisher converts.
- **Otherwise** → the existing `User::PushKey` path, unchanged;
  `created_by = user`.

## UI

Owner-gated via `Namespace::Access` role `owner`.

- **Gem profile** (`/:namespace/:gem`) gains an owner-only "Trusted Publishers"
  section: list / add / remove gem-scoped GitHub Actions publishers (fields:
  repository owner, repository, workflow filename, optional environment,
  optional ref).
- **Namespace level** gains a "Pending Trusted Publishers" area: the same
  fields plus the reserved gem name, for gems that do not exist yet. Once that
  gem is first published, the row moves into the gem's list.
- New controllers: `Namespaces::Gems::TrustedPublishersController` and
  `Namespaces::TrustedPublishersController`, with an authorization helper that
  checks the current user owns the namespace.

## Avo (admin)

- `TrustedPublisher` resource (filter pending vs. active; manual create/revoke).
- `OIDC::Provider` resource (manage the issuer registry / JWKS).
- `OIDC::IdToken` resource (audit log of exchanges).
- `TrustedPublisher::PushKey` resource (publisher + expiry), alongside the
  existing `UserPushKey` resource.

## Security

- RS256-only signature verification against cached JWKS, with key rotation.
- `aud` bound to the Peak host; `exp`/`nbf`/`iat` enforced.
- `jti` uniqueness per provider for replay protection.
- Ambiguous publisher match rejected.
- Short token TTL on minted keys.
- Rate-limiting on the exchange endpoint (mirroring the existing `rate_limit`
  on push-key creation).
- Tokens never logged.
- Only namespace owners manage publishers.

## Testing

- **Unit:** JWT verification (valid / expired / wrong `iss` / wrong `aud` / bad
  signature / replayed `jti`); claim matching (exact match, optional
  environment present/absent, mismatch); provider registry & JWKS caching
  (WebMock-stubbed discovery/JWKS).
- **Integration:** exchange endpoint (mints scoped key; no-match → 401/403;
  pending path); push with a TP key (scoped to its gem; cross-gem and
  cross-namespace rejected; attribution recorded as the publisher; pending
  publisher converts on first push).
- **System:** owner-gated UI flows for creating gem-scoped and pending
  publishers.

## Out of scope

- Long-lived, user-managed API keys.
- Providers other than GitHub Actions (the registry is built to accept them).
- Build provenance / attestation publishing.
