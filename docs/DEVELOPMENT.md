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

## Working & testing events with Stripe

You can find Stripe's up-to-date info via [Workbench > Webhooks](https://dashboard.stripe.com/workbench/webhooks) > Test with a local listener.

First, run `stripe login` and login with your Stripe account that's associated with gem.coop's Stripe account.

Next, use our script to forward Stripe events locally:

```sh
bin/stripe-listen
```

Copy the signing secret from the output, then separately boot the server with `STRIPE__SIGNING_SECRET`:

```sh
STRIPE__SIGNING_SECRET= bin/rails s
```

Finally, you can trigger specific v1 events like so:

```sh
stripe trigger customer.subscription.created
```

Run `stripe trigger --help` to see all possible events.

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
