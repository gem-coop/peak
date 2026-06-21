# Peak Development

Clone the repo, cd into it and run `bin/setup` to get started:

```sh
bin/setup
```

Options:
  - `--reset` resets the database via `bin/rails db:reset`
  - `--dev` runs `bin/dev` to boot the development server.

> [!TIP]
> [bin/sq](bin/sq) lets you query a running server a little more easily, click the link for samples.

> [!TIP]
> [bin/gemspec](bin/gemspec) lets you download a .gem from https://gem.coop, click the link for samples.

# Dependencies

- `homebrew`, we're assuming a working Homebrew installation.
- [`puma-dev`](https://github.com/puma/puma-dev), set it up and run `puma-dev link` from the root dir to setup accessing the app via `http://peak.test`.
- `postgresql@16`, installed via Homebrew (`brew install postgresql@16`) or `docker compose up db`.

## Quick Start

We're using [Oaken](https://github.com/kaspth/oaken) to use code as documentation for our domain model.

So what you see in `db/seeds` is both what gets run via `db:prepare` in `bin/setup` (which runs `db:seed`),
and also the data we test with.

To get up to speed, start reading db/seeds/namespaces:

1. [db/seeds/namespaces/@public.rb](db/seeds/namespaces/@public.rb)
2. [db/seeds/namespaces/@gemcoop.rb](db/seeds/namespaces/@gemcoop.rb)

First is our `@public` namespace, which in production will have thousands of gems that we ingest continually. In our seeds we just ingest a few.

Second is modeling a distinct namespace, here just called `@gemcoop`, which mirrors real life in that it:

- has relatively few gems
- can have gems named the same as in another namespace, without clashing
- can have users with an `owner` role and one with a `plain` permissions role

### Representative controller test

See the push test in [test/controllers/namespaces/gems_controller_test.rb](test/controllers/namespaces/gems_controller_test.rb), which you can run with:

```sh
bin/rails test test/controllers/namespaces/gems_controller_test.rb -i push
```

The test reads [test/fixtures/files/peak/peak-0.1.0.gem](test/fixtures/files/peak/peak-0.1.0.gem) and uploads it.

We've also got a gemspec in [test/fixtures/files/peak/peak.gemspec](test/fixtures/files/peak/peak.gemspec) that we've passed to `gem build` to generate the two `.gem` packages.

## Local Testing gem push

Consider adding a `tmp/Gemfile` like this:

```ruby
source "http://peak.test/@gemcoop"

gem "peak"
```

Then upload our test dependency:

```sh
bin/push @gemcoop test/fixtures/files/peak/peak-0.2.0.gem
```

You should be able to run `bundle lock` now.

## Trusted Publishing

Trusted Publishing lets CI workflows push gems without long-lived API keys. The exchange endpoint accepts a GitHub Actions OIDC JWT and returns a short-lived push token.

### Exchange endpoint

```
POST /:namespace/api/v1/oidc/trusted_publisher/exchange_token
Content-Type: application/json

{"jwt": "<GitHub Actions OIDC token>"}
```

The response is rubygems-compatible:

```json
{
  "rubygems_api_key": "<push token, prefixed gemcoop_tp_>",
  "name":             "trusted-publisher:<gem>",
  "scopes":           ["push_rubygem"],
  "expires_at":       "<ISO8601 timestamp>",
  "namespace":        "@your-namespace",
  "push_url":         "https://gem.coop/@your-namespace/api/v1/gems"
}
```

The token is valid for 30 minutes and is scoped to a single gem: the publisher's gem for gem-scoped publishers, or the reserved gem name for pending publishers (which links to the gem on its first successful push).

### GitHub Actions workflow requirement

The workflow job must request the `id-token: write` permission so the GitHub Actions runtime will issue an OIDC token:

```yaml
permissions:
  id-token: write
  contents: read
```

### Client gem source / RUBYGEMS_HOST

The client must set the gem source or `RUBYGEMS_HOST` to the **namespace-scoped** URL, e.g. `https://gem.coop/@your-namespace`. This is required so that the exchange request (`POST /:namespace/api/v1/oidc/…`) and the push request (`POST /:namespace/api/v1/gems`) resolve as siblings under the same namespace prefix.

Using just `https://gem.coop` (without the namespace) will not work — the exchange endpoint is namespace-scoped by design.

### Configuring publishers

Publishers are managed on the gem's page in the owner UI (visible only to namespace owners).

- **Gem-scoped publisher**: tied to a specific gem from creation. Shown under the gem's settings; the gem name is fixed in the publisher record.
- **Pending publisher**: created without a gem name. On the first successful push the publisher is converted to gem-scoped and linked to the gem that was pushed. Pending publishers are listed on the namespace's trusted publishers page, not on a specific gem page.

Only namespace owners can create, edit, or delete publishers.
