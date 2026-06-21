# Trusted Publishing — UI Completeness Design

Date: 2026-06-20
Status: Approved (pending implementation plan)

## Summary

The trusted-publishing feature (see
`docs/superpowers/specs/2026-06-18-trusted-publishing-design.md`) shipped its
models, exchange API, push-auth, owner-management controllers/views, and Avo
admin resources. A UI audit found the human-facing surface incomplete: a
confirmed crash in the version byline, swallowed flash messages, and management
pages that are unreachable from any navigation. This design completes the
human-facing UI.

Continues on the `trusted-publishing` branch. No schema changes; one display
method is added to a model.

## Decisions

- **Discoverability home:** owner-gated entry points on the gem profile and
  namespace profile pages, plus entry points on the authenticated dashboard.
- **Edit support:** add/remove only. No edit/update of publishers; to change a
  configuration the owner deletes and re-creates. (Out of scope.)
- **Attribution rendering:** a version published via trusted publishing is shown
  on public pages as the source repository plus a marker indicating the
  trusted publisher (e.g. `gem-coop/peak · via GitHub Actions`).
- **CI guidance:** the TP pages show a full copy-paste GitHub Actions workflow
  YAML snippet plus the exchange/push URLs.

## Background — current state

- `Namespace::Gem::Version#created_by` is polymorphic (`User` or
  `TrustedPublisher`) as of the feature branch.
- Public profile pages: `app/views/namespaces/profiles/show.html.erb` and
  `app/views/namespaces/gems/profiles/show.html.erb`. Both render the byline
  partial `app/views/gem/versions/_list.html.erb`, which calls
  `version.created_by.name`.
- `TrustedPublisher` defines no `#name` (only `User` does) — so any version
  authored by a trusted publisher crashes both profile pages with
  `NoMethodError`.
- `app/views/layouts/application.html.erb` has no flash rendering; the nav links
  to Home / Updates / Fellowship / Dashboard (or Sign Up).
- The TP management pages exist at `namespace_gem_trusted_publishers_path`
  (gem-scoped) and `namespace_trusted_publishers_path` (pending), owner-gated by
  `app/controllers/concerns/namespace_authorization.rb`, but nothing links to
  them.
- Public profile controllers (`Namespaces::ProfilesController`,
  `Namespaces::Gems::ProfilesController`) do not resume the session, so
  `Current.user` is nil there even for signed-in visitors. The `Authentication`
  concern exposes `resume_authenticated` (a `before_action :resume_session` that
  populates `Current.session`/`Current.user` if a session cookie exists, without
  requiring authentication).
- `Namespace::Access` has `enum :role, %i[plain owner]` (generates an `owner`
  scope).
- `app/views/user/push_keys/new.html.erb` models CI guidance: it renders
  command snippets from `Peak::Command` inside `<pre><code>`.
- `Peak::Command` (`app/models/peak/command.rb`) holds command/usage snippet
  builders as class methods.
- Both TP controllers permit a `:ref` param, but neither `_form.html.erb`
  includes a `ref` input and neither list row displays `ref`.

## Design

### 1. Defect fixes

**`TrustedPublisher#name`** — add to `app/models/trusted_publisher.rb`:
returns `"#{repository_owner}/#{repository_name}"`. Makes `created_by.name`
safe for the polymorphic association everywhere it is rendered.

**Byline rendering** — add a helper `version_author(version)` (in
`ApplicationHelper`) that returns the author display:

- For a `User` author: the user's `name` (current behavior).
- For a `TrustedPublisher` author: the publisher's `name` (repo) followed by a
  muted marker `· via <provider label>` (e.g. "via GitHub Actions").

The provider label is derived from the publisher's STI subtype via a
`TrustedPublisher#provider_label` method (the `GitHubActions` subclass returns
`"GitHub Actions"`), NOT from the `provider` association. The byline list is
loaded through the `as_byline` scope, whose polymorphic `includes(:created_by)`
cannot cleanly eager-load a nested `provider` (a `User` author has none), so
reading `created_by.provider.name` per row would be an N+1. Deriving the label
from the subtype avoids any per-row query.

`app/views/gem/versions/_list.html.erb` calls `version_author(version)` instead
of `version.created_by.name`. This fixes the crash on the gem and namespace
profile pages and renders the agreed attribution.

**Flash region** — add to `app/views/layouts/application.html.erb`, before
`<%= yield %>`, a block rendering each flash entry with an appropriate role
(`alert` for `:alert`, `status` otherwise). This surfaces the create/destroy
success and owner-gate messages emitted by the TP controllers and the
`NamespaceAuthorization` concern.

### 2. Ownership-aware discoverability

**Ownership helper** — add `owner_of?(namespace)` to `ApplicationHelper`:

```ruby
def owner_of?(namespace)
  Current.user? && namespace.accesses.owner.exists?(user: Current.user)
end
```

**Session resume on public profiles** — `Namespaces::ProfilesController` and
`Namespaces::Gems::ProfilesController` call `resume_authenticated` so
`Current.user` is populated for signed-in visitors without forcing login.

**Entry points:**

- **Gem profile** (`namespaces/gems/profiles/show.html.erb`): when
  `owner_of?(@gem.namespace)`, render an owner-only "Trusted Publishers" link to
  `namespace_gem_trusted_publishers_path(namespace: @gem.namespace.name,
  gem_id: @gem.name)`.
- **Namespace profile** (`namespaces/profiles/show.html.erb`): when
  `owner_of?(@index.namespace)`, render an owner-only "Pending Trusted
  Publishers" link to
  `namespace_trusted_publishers_path(namespace: @index.namespace.name)`.
- **Dashboard** (`dashboard/show.html.erb`): for each namespace the user owns
  (filter the existing list by `owner_of?`), render a "Trusted publishers" link
  to `namespace_trusted_publishers_path`.
- **Back-links** — each TP index view gains a back-link to its parent: the
  gem-scoped page links to the gem profile
  (`namespace_gem_path(@gem.namespace, @gem, index: nil)`); the pending page
  links to the namespace profile (`namespace_path(@namespace.name)`).

### 3. TP page content completeness

**`ref` field** — add a `ref` text input (labelled optional) to both
`app/views/namespaces/gems/trusted_publishers/_form.html.erb` and
`app/views/namespaces/trusted_publishers/_form.html.erb`. Display `ref` in both
index list rows next to `environment` (shown only when present, matching the
existing `environment` conditional).

**CI guidance** — add
`Peak::Command.trusted_publisher_workflow(namespace:, gem:)` returning a
copy-paste GitHub Actions workflow YAML snippet that includes:

- `permissions: { id-token: write, contents: read }`
- the exchange request against the namespace-scoped host
- the push against the namespace-scoped host for `gem`

Render the snippet (inside `<pre><code>`, mirroring `push_keys/new`) on both TP
index pages, along with the exchange URL
(`namespace_oidc_exchange_token_url`) and push URL
(`namespace_gem_push_url`). The pending page uses the reserved `gem_name` for
the snippet's gem.

**Pending → converted lifecycle** — on the namespace TP index
(`namespaces/trusted_publishers/index.html.erb`), add an "Active publishers"
section listing the namespace's non-pending publishers
(`current_namespace.trusted_publishers.where.not(gem_id: nil)`), each linking to
that gem's TP page (`namespace_gem_trusted_publishers_path`). This explains
where a pending publisher went after it converted on first push. The controller
loads this collection alongside the existing pending list.

## Components / files

**Modify:**
- `app/models/trusted_publisher.rb` — add `#name`; add `#provider_label` (base
  + `GitHubActions` subclass override).
- `app/models/peak/command.rb` — add `trusted_publisher_workflow`.
- `app/helpers/application_helper.rb` — add `owner_of?` and `version_author`.
- `app/views/layouts/application.html.erb` — flash region.
- `app/views/gem/versions/_list.html.erb` — use `version_author`.
- `app/controllers/namespaces/profiles_controller.rb`,
  `app/controllers/namespaces/gems/profiles_controller.rb` —
  `resume_authenticated`.
- `app/views/namespaces/profiles/show.html.erb`,
  `app/views/namespaces/gems/profiles/show.html.erb`,
  `app/views/dashboard/show.html.erb` — owner-gated links.
- `app/controllers/namespaces/trusted_publishers_controller.rb` — load the
  active (converted) publishers collection for the index.
- `app/views/namespaces/gems/trusted_publishers/{index,_form}.html.erb`,
  `app/views/namespaces/trusted_publishers/{index,_form}.html.erb` — `ref`
  field + display, CI snippet, back-links, active-publishers section.

## Error handling

- Owner-gated links never render for anonymous or non-owner visitors;
  `owner_of?` returns false when `Current.user` is nil.
- The byline helper handles both author types; no author type can reach an
  unsupported method.

## Testing

- **Model:** `TrustedPublisher#name`.
- **Helper:** `owner_of?` (owner true; non-owner false; anonymous false);
  `version_author` for a `User` and for a `TrustedPublisher` author.
- **Byline regression (integration):** the gem profile and namespace profile
  pages render a gem whose latest version's `created_by` is a `TrustedPublisher`
  without raising, and show the repo + provider marker.
- **Discoverability (integration):** gem and namespace profiles show the
  owner-only TP links for a signed-in owner and hide them for a non-owner and
  for an anonymous visitor; the dashboard shows TP links for owned namespaces.
- **TP pages (integration):** creating a publisher with a `ref` persists and
  the value displays; the CI workflow snippet is present; back-links resolve;
  the namespace page's active-publishers section lists a converted publisher.
- **Flash (integration):** following the non-owner gate redirect renders the
  alert text.

## Out of scope

- Edit/update of trusted publishers (add/remove only).
- Any change to the exchange or push API.
- Avo admin resources.
- Model-level uniqueness validation for duplicate publisher configurations
  (noted by the audit; deferred).
