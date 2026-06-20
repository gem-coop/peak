# Trusted Publishing UI Completeness Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Complete the human-facing UI for trusted publishing — fix the byline crash and swallowed flash, make the owner-management pages discoverable, and round out the management pages (ref field, CI snippet, converted-publisher visibility).

**Architecture:** Add a polymorphic-safe author byline (model display methods + a view helper), a flash region in the layout, an ownership helper plus session-resume on the public profile controllers so owner-only links can render, and content additions to the existing trusted-publisher pages. No schema or API changes.

**Tech Stack:** Rails 8.1, Ruby 4.0.5, Minitest + Oaken seeds, ERB + vanilla CSS, HTML rendered through the `application` layout (needs the JS asset built for tests).

## Global Constraints

- No database/schema changes and no exchange/push API changes in this plan. One display method (`#name`) and one label method (`#provider_label`) are added to a model; no columns.
- Edit/update of publishers is OUT OF SCOPE (add/remove only). Do not add edit/update actions.
- Commits use Jujutsu (`jj commit -m "<msg>"`), each message ending with a blank line then exactly:
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`
- Run tests with this exact form from the repo root (the shell defaults to system Ruby 2.6 and inherits a real `SLACK_WEBHOOK_URL`):
  ```
  export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH"
  bun run build
  env -u SLACK_WEBHOOK_URL bin/rails test <path>
  ```
  Every task here renders the `application` layout, so `bun run build` is required once before running tests (it generates the gitignored `app/assets/builds/application.js`). A `The asset 'application.js' was not found` error means you skipped it; an `undefined method 'map' for nil` in `teardown_transactional_fixtures` means you forgot `env -u SLACK_WEBHOOK_URL`. Do NOT use system ruby, `asdf set`, `.tool-versions`, or `BUNDLE_WITH=avo`.
- Baseline suite before this plan: 122 runs, 0 failures, 1 skip (Avo, expected). Add no new failures; the Avo skip stays.
- Do NOT commit `app/assets/builds/*` (gitignored) — verify it is not in any commit.
- The byline provider marker must NOT trigger a per-row query: derive the provider label from the publisher's STI subtype (`#provider_label`), never from the `provider` association (the `as_byline` scope's polymorphic `includes(:created_by)` cannot eager-load a nested `provider`).
- Owner gating uses `owner_of?(namespace)` (Task 3); it must return false for anonymous and non-owner visitors.
- Oaken test data: `namespaces.gemcoop` (owner `users.owner`, non-owner `users.plain`), `gems.peak` (one version, ref `0.1.0`), `oidc_providers.github`. Sign in in integration tests with `sign_in_as(users.owner)` / `sign_in_as(users.plain)` (defined in `test/test_helper.rb`).

---

## File Structure

**Modify (app):**
- `app/models/trusted_publisher.rb` — `#name`, `#provider_label` (base fallback).
- `app/models/trusted_publisher/github_actions.rb` — `#provider_label` override.
- `app/models/peak/command.rb` — `self.trusted_publisher_workflow(host:, gem:)`.
- `app/helpers/application_helper.rb` — `version_author(version)`, `owner_of?(namespace)`.
- `app/views/gem/versions/_list.html.erb` — use `version_author`.
- `app/views/layouts/application.html.erb` — flash region.
- `app/controllers/namespaces/profiles_controller.rb` — `resume_authenticated`.
- `app/controllers/namespaces/gems/profiles_controller.rb` — `resume_authenticated`.
- `app/views/namespaces/profiles/show.html.erb` — owner-only pending-TP link.
- `app/views/namespaces/gems/profiles/show.html.erb` — owner-only TP link.
- `app/views/dashboard/show.html.erb` — owner-only TP links per owned namespace.
- `app/controllers/namespaces/trusted_publishers_controller.rb` — load active (converted) publishers in `index`.
- `app/views/namespaces/gems/trusted_publishers/{index,_form}.html.erb` — ref field/display, CI snippet, back-link.
- `app/views/namespaces/trusted_publishers/{index,_form}.html.erb` — ref field/display, CI snippet, back-link, active-publishers section.

**Test:**
- `test/models/trusted_publisher/github_actions_test.rb`, `test/models/peak/command_test.rb` (create), `test/helpers/application_helper_test.rb` (create), and integration tests under `test/controllers/namespaces/**` and `test/controllers/dashboard_controller_test.rb`.

---

## Task 1: Polymorphic-safe author byline (fix the crash)

**Files:**
- Modify: `app/models/trusted_publisher.rb`, `app/models/trusted_publisher/github_actions.rb`, `app/helpers/application_helper.rb`, `app/views/gem/versions/_list.html.erb`
- Test: `test/models/trusted_publisher/github_actions_test.rb`, `test/helpers/application_helper_test.rb` (create), `test/controllers/namespaces/gems/profiles_controller_test.rb` (create or append), `test/controllers/namespaces/profiles_controller_test.rb`

**Interfaces:**
- Produces:
  - `TrustedPublisher#name -> String` (`"<repository_owner>/<repository_name>"`)
  - `TrustedPublisher#provider_label -> String` (base `"trusted publisher"`; `GitHubActions` `"GitHub Actions"`)
  - `ApplicationHelper#version_author(version) -> String/SafeBuffer` (User → `name`; TrustedPublisher → `name` + muted "· via <provider_label>")

- [ ] **Step 1: Write the failing model + helper tests**

Append to `test/models/trusted_publisher/github_actions_test.rb` (inside the class):

```ruby
  test "name is owner/repo" do
    assert_equal "gem-coop/peak", build.name
  end

  test "provider_label" do
    assert_equal "GitHub Actions", build.provider_label
    assert_equal "trusted publisher", TrustedPublisher.new.provider_label
  end
```

Create `test/helpers/application_helper_test.rb`:

```ruby
require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "version_author renders a user's name" do
    version = versions.by gems.peak, ref: "0.1.0"
    assert_equal users.owner.name, version_author(version)
  end

  test "version_author renders a trusted publisher repo with marker" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    version = versions.by gems.peak, ref: "0.1.0"
    version.update!(created_by: publisher)

    html = version_author(version)
    assert_includes html, "gem-coop/peak"
    assert_includes html, "via GitHub Actions"
  end
end
```

> `versions.by gems.peak, ref: "0.1.0"` returns the seeded peak version (created_by `users.owner`). `build` is the existing helper in the github_actions_test that builds a `TrustedPublisher::GitHubActions` with owner `gem-coop`, repo `peak`.

- [ ] **Step 2: Run them to verify they fail**

Run: `export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH" && bun run build && env -u SLACK_WEBHOOK_URL bin/rails test test/models/trusted_publisher/github_actions_test.rb test/helpers/application_helper_test.rb`
Expected: FAIL (`NoMethodError` for `name`/`provider_label`/`version_author`).

- [ ] **Step 3: Add the model methods**

In `app/models/trusted_publisher.rb`, after the `link_gem!` method (before the `matches?` line), add:

```ruby
  def name = "#{repository_owner}/#{repository_name}"
  def provider_label = "trusted publisher"
```

In `app/models/trusted_publisher/github_actions.rb`, add a public method (after `matches?`, before `private`):

```ruby
  def provider_label = "GitHub Actions"
```

- [ ] **Step 4: Add the helper**

In `app/helpers/application_helper.rb`, add inside the module:

```ruby
  def version_author(version)
    author = version.created_by
    return author.name unless author.is_a?(TrustedPublisher)

    safe_join([author.name, tag.i("· via #{author.provider_label}", style: "color: var(--secondary);")], " ")
  end
```

- [ ] **Step 5: Use the helper in the byline partial**

In `app/views/gem/versions/_list.html.erb`, replace line 6:

```erb
      <%= version.created_by.name %>
```

with:

```erb
      <%= version_author(version) %>
```

- [ ] **Step 6: Run the model + helper tests**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/models/trusted_publisher/github_actions_test.rb test/helpers/application_helper_test.rb`
Expected: PASS.

- [ ] **Step 7: Write the profile-page regression tests**

Append to `test/controllers/namespaces/profiles_controller_test.rb` (inside the class; if the file doesn't exist, create it with `require "test_helper"` and `class Namespaces::ProfilesControllerTest < ActionDispatch::IntegrationTest`):

```ruby
  test "renders a version authored by a trusted publisher" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    versions.by(gems.peak, ref: "0.1.0").update!(created_by: publisher)

    get namespace_url(namespaces.gemcoop.name)
    assert_response :success
    assert_includes response.body, "gem-coop/peak"
  end
```

Create `test/controllers/namespaces/gems/profiles_controller_test.rb`:

```ruby
require "test_helper"

class Namespaces::Gems::ProfilesControllerTest < ActionDispatch::IntegrationTest
  test "renders a version authored by a trusted publisher" do
    publisher = TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")
    versions.by(gems.peak, ref: "0.1.0").update!(created_by: publisher)

    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_response :success
    assert_includes response.body, "gem-coop/peak"
    assert_includes response.body, "via GitHub Actions"
  end
end
```

- [ ] **Step 8: Run the regression tests**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/profiles_controller_test.rb test/controllers/namespaces/gems/profiles_controller_test.rb`
Expected: PASS (these would raise `NoMethodError` without the fix).

- [ ] **Step 9: Run the full suite**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test`
Expected: 0 failures, 0 errors, 1 skip (Avo).

- [ ] **Step 10: Commit**

```bash
jj commit -m "Fix version byline for trusted-publisher authors

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 2: Flash region in the layout

**Files:**
- Modify: `app/views/layouts/application.html.erb`
- Test: `test/controllers/namespaces/trusted_publishers_controller_test.rb` (append)

**Interfaces:**
- Consumes: the existing `NamespaceAuthorization` owner-gate redirect (redirects with `alert:` to `namespace_path`).
- Produces: flash messages render on every page.

- [ ] **Step 1: Write the failing test**

Append to `test/controllers/namespaces/trusted_publishers_controller_test.rb` (inside the class):

```ruby
  test "non-owner sees the owner-gate alert via flash" do
    sign_in_as users.plain
    get namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
    follow_redirect!
    assert_includes response.body, "must be an owner"
  end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH" && bun run build && env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/trusted_publishers_controller_test.rb -n /flash/`
Expected: FAIL (the alert text is not in the body — no flash region renders it).

- [ ] **Step 3: Add the flash region**

In `app/views/layouts/application.html.erb`, between the closing `</nav>` (line 43) and `<%= yield %>` (line 45), insert:

```erb
      <% flash.each do |type, message| %>
        <%= tag.p message, role: (type.to_sym == :alert ? "alert" : "status"), class: "flash flash-#{type}" %>
      <% end %>
```

- [ ] **Step 4: Run the test**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/trusted_publishers_controller_test.rb -n /flash/`
Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test`
Expected: 0 failures, 0 errors, 1 skip.

- [ ] **Step 6: Commit**

```bash
jj commit -m "Render flash messages in the application layout

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 3: Ownership helper + profile entry points

**Files:**
- Modify: `app/helpers/application_helper.rb`, `app/controllers/namespaces/profiles_controller.rb`, `app/controllers/namespaces/gems/profiles_controller.rb`, `app/views/namespaces/profiles/show.html.erb`, `app/views/namespaces/gems/profiles/show.html.erb`
- Test: `test/helpers/application_helper_test.rb`, `test/controllers/namespaces/profiles_controller_test.rb`, `test/controllers/namespaces/gems/profiles_controller_test.rb`

**Interfaces:**
- Consumes: `version_author` (Task 1, unaffected).
- Produces: `ApplicationHelper#owner_of?(namespace) -> Boolean`. The two public profile controllers populate `Current.user` for signed-in visitors via `resume_authenticated`.

- [ ] **Step 1: Write the failing helper test**

Append to `test/helpers/application_helper_test.rb` (inside the class):

```ruby
  test "owner_of? is true only for an owner" do
    Current.session = nil
    refute owner_of?(namespaces.gemcoop)

    Current.session = users.plain.sessions.create!(ip_address: "1.1.1.1", user_agent: "test")
    refute owner_of?(namespaces.gemcoop)

    Current.session = users.owner.sessions.create!(ip_address: "1.1.1.1", user_agent: "test")
    assert owner_of?(namespaces.gemcoop)
  ensure
    Current.session = nil
  end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH" && bun run build && env -u SLACK_WEBHOOK_URL bin/rails test test/helpers/application_helper_test.rb -n /owner_of/`
Expected: FAIL (`NoMethodError: owner_of?`).

- [ ] **Step 3: Add the helper**

In `app/helpers/application_helper.rb`, add inside the module:

```ruby
  def owner_of?(namespace)
    Current.user? && namespace.accesses.owner.exists?(user: Current.user)
  end
```

- [ ] **Step 4: Run the helper test**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/helpers/application_helper_test.rb -n /owner_of/`
Expected: PASS.

- [ ] **Step 5: Resume sessions on the public profile controllers**

In `app/controllers/namespaces/profiles_controller.rb`, add as the first line inside the class (above `before_action :set_index`):

```ruby
  resume_authenticated
```

In `app/controllers/namespaces/gems/profiles_controller.rb`, add as the first line inside the class (above `before_action :set_index`):

```ruby
  resume_authenticated
```

- [ ] **Step 6: Write the failing profile-link tests**

Append to `test/controllers/namespaces/gems/profiles_controller_test.rb` (inside the class):

```ruby
  test "owner sees the trusted publishers link" do
    sign_in_as users.owner
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_select "a[href=?]",
      namespace_gem_trusted_publishers_path(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name)
  end

  test "non-owner does not see the trusted publishers link" do
    sign_in_as users.plain
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_select "a[href=?]",
      namespace_gem_trusted_publishers_path(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name), count: 0
  end

  test "anonymous does not see the trusted publishers link" do
    get namespace_gem_url(namespaces.gemcoop, gems.peak, index: nil)
    assert_select "a[href=?]",
      namespace_gem_trusted_publishers_path(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name), count: 0
  end
```

Append to `test/controllers/namespaces/profiles_controller_test.rb` (inside the class):

```ruby
  test "owner sees the pending trusted publishers link" do
    sign_in_as users.owner
    get namespace_url(namespaces.gemcoop.name)
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name)
  end

  test "non-owner does not see the pending trusted publishers link" do
    sign_in_as users.plain
    get namespace_url(namespaces.gemcoop.name)
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name), count: 0
  end
```

- [ ] **Step 7: Run them to verify they fail**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/gems/profiles_controller_test.rb test/controllers/namespaces/profiles_controller_test.rb`
Expected: FAIL on the new link assertions (links not present yet).

- [ ] **Step 8: Add the owner-only link to the gem profile**

In `app/views/namespaces/gems/profiles/show.html.erb`, immediately after the `<h1>…</h1>` block (after line 9), add:

```erb
  <% if owner_of?(@gem.namespace) %>
    <p><%= link_to "Trusted Publishers", namespace_gem_trusted_publishers_path(namespace: @gem.namespace.name, gem_id: @gem.name) %></p>
  <% end %>
```

- [ ] **Step 9: Add the owner-only link to the namespace profile**

In `app/views/namespaces/profiles/show.html.erb`, inside the `<div>` that holds the namespace `<h1>` and owner list, after the owners `</ul>` (after line 15), add:

```erb
    <% if owner_of?(@index.namespace) %>
      <p><%= link_to "Pending Trusted Publishers", namespace_trusted_publishers_path(namespace: @index.namespace.name) %></p>
    <% end %>
```

- [ ] **Step 10: Run the profile-link tests**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/gems/profiles_controller_test.rb test/controllers/namespaces/profiles_controller_test.rb`
Expected: PASS.

- [ ] **Step 11: Run the full suite**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test`
Expected: 0 failures, 0 errors, 1 skip.

- [ ] **Step 12: Commit**

```bash
jj commit -m "Surface trusted publisher links to owners on profile pages

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 4: Dashboard entry points + back-links

**Files:**
- Modify: `app/views/dashboard/show.html.erb`, `app/views/namespaces/gems/trusted_publishers/index.html.erb`, `app/views/namespaces/trusted_publishers/index.html.erb`
- Test: `test/controllers/dashboard_controller_test.rb` (create), `test/controllers/namespaces/gems/trusted_publishers_controller_test.rb`, `test/controllers/namespaces/trusted_publishers_controller_test.rb`

**Interfaces:**
- Consumes: `owner_of?` (Task 3); route helpers `namespace_trusted_publishers_path`, `namespace_gem_path`, `namespace_path`.

- [ ] **Step 1: Write the failing dashboard test**

Create `test/controllers/dashboard_controller_test.rb`:

```ruby
require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  test "owner sees a trusted publishers link for an owned namespace" do
    sign_in_as users.owner
    get dashboard_url
    assert_response :success
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name)
  end

  test "non-owner sees no trusted publishers link" do
    sign_in_as users.plain
    get dashboard_url
    assert_response :success
    assert_select "a[href=?]", namespace_trusted_publishers_path(namespace: namespaces.gemcoop.name), count: 0
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH" && bun run build && env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: FAIL (owner case: link missing).

- [ ] **Step 3: Add the dashboard link**

In `app/views/dashboard/show.html.erb`, replace the namespaces `<li>` block (lines 17–25) with:

```erb
    <% Current.user.namespaces.each do |namespace| %>
      <li>
        <% if namespace.approved_at? %>
          <%= link_to namespace.name, namespace %>
          <% if owner_of?(namespace) %>
            · <%= link_to "Trusted publishers", namespace_trusted_publishers_path(namespace: namespace.name) %>
          <% end %>
        <% else %>
          <%= namespace.name %> <small>(pending approval)</small>
        <% end %>
      </li>
    <% end %>
```

- [ ] **Step 4: Run the dashboard test**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/dashboard_controller_test.rb`
Expected: PASS.

- [ ] **Step 5: Write the failing back-link tests**

Append to `test/controllers/namespaces/gems/trusted_publishers_controller_test.rb` (inside the class):

```ruby
  test "index has a back-link to the gem profile" do
    sign_in_as users.owner
    get namespace_gem_trusted_publishers_url(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name)
    assert_select "a[href=?]", namespace_gem_path(namespaces.gemcoop, gems.peak, index: nil)
  end
```

Append to `test/controllers/namespaces/trusted_publishers_controller_test.rb` (inside the class):

```ruby
  test "index has a back-link to the namespace profile" do
    sign_in_as users.owner
    get namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
    assert_select "a[href=?]", namespace_path(namespaces.gemcoop.name)
  end
```

- [ ] **Step 6: Run them to verify they fail**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/gems/trusted_publishers_controller_test.rb test/controllers/namespaces/trusted_publishers_controller_test.rb -n /back-link/`
Expected: FAIL (no back-links yet).

- [ ] **Step 7: Add the back-links**

In `app/views/namespaces/gems/trusted_publishers/index.html.erb`, after line 1 (`<% page.title = … %>`), add:

```erb
<p><%= link_to "← #{@gem.namespace.name}/#{@gem.name}", namespace_gem_path(@gem.namespace, @gem, index: nil) %></p>
```

In `app/views/namespaces/trusted_publishers/index.html.erb`, after line 1 (`<% page.title = … %>`), add:

```erb
<p><%= link_to "← #{@namespace.name}", namespace_path(@namespace.name) %></p>
```

- [ ] **Step 8: Run the back-link tests**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/gems/trusted_publishers_controller_test.rb test/controllers/namespaces/trusted_publishers_controller_test.rb -n /back-link/`
Expected: PASS.

- [ ] **Step 9: Run the full suite**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test`
Expected: 0 failures, 0 errors, 1 skip.

- [ ] **Step 10: Commit**

```bash
jj commit -m "Add dashboard entry points and back-links for trusted publishers

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 5: ref field + CI workflow snippet on the TP pages

**Files:**
- Modify: `app/models/peak/command.rb`, `app/views/namespaces/gems/trusted_publishers/{index,_form}.html.erb`, `app/views/namespaces/trusted_publishers/{index,_form}.html.erb`
- Test: `test/models/peak/command_test.rb` (create), `test/controllers/namespaces/gems/trusted_publishers_controller_test.rb`, `test/controllers/namespaces/trusted_publishers_controller_test.rb`

**Interfaces:**
- Produces: `Peak::Command.trusted_publisher_workflow(host:, gem:) -> String` (a GitHub Actions YAML snippet).
- Consumes: route helpers `namespace_url`, `namespace_oidc_exchange_token_url`, `namespace_gem_push_url`.

- [ ] **Step 1: Write the failing command test**

Create `test/models/peak/command_test.rb`:

```ruby
require "test_helper"

class Peak::CommandTest < ActiveSupport::TestCase
  test "trusted_publisher_workflow includes id-token permission, host and gem" do
    yaml = Peak::Command.trusted_publisher_workflow(host: "https://gem.coop/@gemcoop", gem: "peak")
    assert_includes yaml, "id-token: write"
    assert_includes yaml, "https://gem.coop/@gemcoop"
    assert_includes yaml, "peak.gemspec"
    assert_includes yaml, "gem push --host https://gem.coop/@gemcoop"
  end
end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH" && bun run build && env -u SLACK_WEBHOOK_URL bin/rails test test/models/peak/command_test.rb`
Expected: FAIL (`NoMethodError: trusted_publisher_workflow`).

- [ ] **Step 3: Add the command builder**

In `app/models/peak/command.rb`, add inside the class:

```ruby
  def self.trusted_publisher_workflow(host:, gem:)
    <<~YAML
      name: Release #{gem}
      on:
        push:
          tags: ["v*"]
      permissions:
        id-token: write
        contents: read
      jobs:
        push:
          runs-on: ubuntu-latest
          steps:
            - uses: actions/checkout@v4
            - uses: ruby/setup-ruby@v1
              with:
                bundler-cache: true
            - uses: rubygems/configure-rubygems-credentials@main
              with:
                gem-server: #{host}
            - run: gem build #{gem}.gemspec
            - run: gem push --host #{host} #{gem}-*.gem
    YAML
  end
```

- [ ] **Step 4: Run the command test**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/models/peak/command_test.rb`
Expected: PASS.

- [ ] **Step 5: Write the failing view tests (ref + snippet)**

Append to `test/controllers/namespaces/gems/trusted_publishers_controller_test.rb` (inside the class):

```ruby
  test "form has a ref field and the page shows the CI snippet" do
    sign_in_as users.owner
    get namespace_gem_trusted_publishers_url(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name)
    assert_select "input[name=?]", "trusted_publisher[ref]"
    assert_includes response.body, "id-token: write"
  end

  test "created ref is persisted and displayed" do
    sign_in_as users.owner
    post namespace_gem_trusted_publishers_url(namespace: namespaces.gemcoop.name, gem_id: gems.peak.name),
      params: { trusted_publisher: { repository_owner: "gem-coop", repository_name: "peak",
        workflow_filename: "release.yml", ref: "refs/heads/main" } }
    follow_redirect!
    assert_includes response.body, "refs/heads/main"
    assert_equal "refs/heads/main", gems.peak.trusted_publishers.order(:created_at).last.ref
  end
```

Append to `test/controllers/namespaces/trusted_publishers_controller_test.rb` (inside the class):

```ruby
  test "form has a ref field and the page shows the CI snippet" do
    sign_in_as users.owner
    get namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
    assert_select "input[name=?]", "trusted_publisher[ref]"
    assert_includes response.body, "id-token: write"
  end
```

- [ ] **Step 6: Run them to verify they fail**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/gems/trusted_publishers_controller_test.rb test/controllers/namespaces/trusted_publishers_controller_test.rb -n /ref|snippet|CI/`
Expected: FAIL (no ref field / snippet yet).

- [ ] **Step 7: Add the ref field to both forms**

In `app/views/namespaces/gems/trusted_publishers/_form.html.erb`, after the environment field (after line 22, before the submit button), add:

```erb
  <%= form.label :ref, "Ref (optional, e.g. refs/heads/main)" %>
  <%= form.text_field :ref %>
```

In `app/views/namespaces/trusted_publishers/_form.html.erb`, after the environment field (after line 25, before the submit button), add:

```erb
  <%= form.label :ref, "Ref (optional, e.g. refs/heads/main)" %>
  <%= form.text_field :ref %>
```

- [ ] **Step 8: Display ref in both index list rows**

In `app/views/namespaces/gems/trusted_publishers/index.html.erb`, after the environment line (line 13), add:

```erb
        <%= " (ref: #{publisher.ref})" if publisher.ref.present? %>
```

In `app/views/namespaces/trusted_publishers/index.html.erb`, after the workflow line (line 13), add:

```erb
        <%= " (env: #{publisher.environment})" if publisher.environment.present? %>
        <%= " (ref: #{publisher.ref})" if publisher.ref.present? %>
```

- [ ] **Step 9: Add the CI snippet to both index pages**

In `app/views/namespaces/gems/trusted_publishers/index.html.erb`, before the final `<h2>Add a GitHub Actions publisher</h2>` line, add:

```erb
<h2>Set up GitHub Actions</h2>
<p>Add a workflow like this, then pushes from that workflow need no stored key:</p>
<pre><code><%= Peak::Command.trusted_publisher_workflow(host: namespace_url(@gem.namespace.name), gem: @gem.name) -%></code></pre>
<p>Exchange endpoint: <code><%= namespace_oidc_exchange_token_url(namespace: @gem.namespace.name) %></code></p>
```

In `app/views/namespaces/trusted_publishers/index.html.erb`, before the final `<h2>Reserve a gem name</h2>` line, add:

```erb
<h2>Set up GitHub Actions</h2>
<p>After reserving a name, add a workflow like this (replace the gem name if needed):</p>
<pre><code><%= Peak::Command.trusted_publisher_workflow(host: namespace_url(@namespace.name), gem: @trusted_publishers.first&.gem_name || "<your-gem>") -%></code></pre>
<p>Exchange endpoint: <code><%= namespace_oidc_exchange_token_url(namespace: @namespace.name) %></code></p>
```

- [ ] **Step 10: Run the view tests**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/gems/trusted_publishers_controller_test.rb test/controllers/namespaces/trusted_publishers_controller_test.rb`
Expected: PASS.

- [ ] **Step 11: Run the full suite**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test`
Expected: 0 failures, 0 errors, 1 skip.

- [ ] **Step 12: Commit**

```bash
jj commit -m "Add ref field and CI workflow snippet to trusted publisher pages

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Task 6: Pending → converted publisher visibility

**Files:**
- Modify: `app/controllers/namespaces/trusted_publishers_controller.rb`, `app/views/namespaces/trusted_publishers/index.html.erb`
- Test: `test/controllers/namespaces/trusted_publishers_controller_test.rb`

**Interfaces:**
- Consumes: `owner_of?`, `Namespace#trusted_publishers`, route helper `namespace_gem_trusted_publishers_path`.
- Produces: the namespace pending page lists converted (gem-present) publishers with links to their gem's TP page.

- [ ] **Step 1: Write the failing test**

Append to `test/controllers/namespaces/trusted_publishers_controller_test.rb` (inside the class):

```ruby
  test "active section lists a converted publisher linking to its gem page" do
    TrustedPublisher::GitHubActions.create!(
      namespace: namespaces.gemcoop, gem: gems.peak, gem_name: "peak",
      provider: oidc_providers.github,
      repository_owner: "gem-coop", repository_name: "peak", workflow_filename: "release.yml")

    sign_in_as users.owner
    get namespace_trusted_publishers_url(namespace: namespaces.gemcoop.name)
    assert_select "a[href=?]",
      namespace_gem_trusted_publishers_path(namespace: namespaces.gemcoop.name, gem_id: "peak")
  end
```

- [ ] **Step 2: Run it to verify it fails**

Run: `export PATH="$HOME/.bun/bin:$HOME/.asdf/installs/ruby/ruby-4.0.5/bin:$PATH" && bun run build && env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/trusted_publishers_controller_test.rb -n /active section/`
Expected: FAIL (no active section / link).

- [ ] **Step 3: Load the active publishers in the controller**

In `app/controllers/namespaces/trusted_publishers_controller.rb`, change the `index` action (lines 4–7) to:

```ruby
  def index
    @trusted_publishers = current_namespace.trusted_publishers.pending.order(:created_at)
    @active_publishers = current_namespace.trusted_publishers.where.not(gem_id: nil).order(:created_at)
    @trusted_publisher = TrustedPublisher::GitHubActions.new
  end
```

- [ ] **Step 4: Render the active section**

In `app/views/namespaces/trusted_publishers/index.html.erb`, after the pending block (after the `<% end %>` that closes the `if @trusted_publishers.any?` / `else` on line 22), add:

```erb
<% if @active_publishers.any? %>
  <h2>Active publishers</h2>
  <p>These reserved names have been published and are now managed on their gem pages.</p>
  <ul>
    <% @active_publishers.each do |publisher| %>
      <li>
        <%= link_to publisher.gem_name,
          namespace_gem_trusted_publishers_path(namespace: @namespace.name, gem_id: publisher.gem_name) %>
        — <code><%= publisher.repository_owner %>/<%= publisher.repository_name %></code>
      </li>
    <% end %>
  </ul>
<% end %>
```

- [ ] **Step 5: Run the test**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test test/controllers/namespaces/trusted_publishers_controller_test.rb -n /active section/`
Expected: PASS.

- [ ] **Step 6: Run the full suite**

Run: `env -u SLACK_WEBHOOK_URL bin/rails test`
Expected: 0 failures, 0 errors, 1 skip.

- [ ] **Step 7: Run linters**

Run: `bin/rubocop` and `bin/brakeman --no-pager`
Expected: rubocop clean on changed files; brakeman 0 new warnings. Fix any offenses introduced by this plan's files.

- [ ] **Step 8: Commit**

```bash
jj commit -m "Show converted trusted publishers on the namespace page

Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>"
```

---

## Self-Review

**Spec coverage:**
- Byline crash fix (`#name`, `version_author`, partial) → Task 1.
- Provider marker from STI subtype, no N+1 (`#provider_label`) → Task 1.
- Flash region → Task 2.
- `owner_of?` helper + `resume_authenticated` on public profiles → Task 3.
- Gem profile + namespace profile owner links → Task 3.
- Dashboard owner links + back-links → Task 4.
- `ref` field + display → Task 5.
- CI workflow snippet (`Peak::Command.trusted_publisher_workflow`) on both pages → Task 5.
- Pending→converted "Active publishers" section → Task 6.
- Testing (model, helper, byline regression, discoverability, TP page content, flash, lifecycle) → distributed across all tasks.
- Out of scope (edit/update, API, Avo, uniqueness validation) → not implemented, as required.

**Placeholder scan:** No TBD/TODO; every code step shows full code and exact commands.

**Type consistency:** `version_author(version)`, `owner_of?(namespace)`, `TrustedPublisher#name`/`#provider_label`, and `Peak::Command.trusted_publisher_workflow(host:, gem:)` are referenced identically wherever they appear. Route helpers (`namespace_url`, `namespace_gem_path`, `namespace_trusted_publishers_path`, `namespace_gem_trusted_publishers_path`, `namespace_oidc_exchange_token_url`) match the app's existing routes.

**Note for execution:** Tasks 4–6 each touch the two TP index views and one controller already edited by earlier tasks; execute in order so each implementer edits the current file state. Confirm route helper names with `bin/rails routes -g trusted_publisher` if any `assert_select`/`link_to` path fails to resolve.
