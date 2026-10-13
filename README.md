# Price Paid Data (PPD) Explorer

This is the HM Land Registry [PPD Explorer](http://landregistry.data.gov.uk/app/ppd),
a web application that allows users to search and explore Price Paid linked-data for
England and Wales.

Please see the other repositories in the [HM Land Registry Open
Data](https://github.com/epimorphics/hmlr-linked-data/) project for more details.

For more information about this project visit [the
wiki](https://github.com/epimorphics/ppd-explorer/wiki).

## Contents

- [Tech stack](#tech-stack)
- [Developer setup](#developer-setup)
- [Data API](#data-api)
- [Running locally](#running-locally)
- [Testing](#testing)
- [E2E testing](#e2e-testing)
- [Linting](#linting)
- [Building and publishing](#building-and-publishing)
- [Releases](#releases)
- [Environments](#environments)
- [Observability](#observability)
- [Dependency maintenance](#dependency-maintenance)

## Tech stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8.1, served via Puma |
| Assets | Sprockets asset pipeline + Dart Sass |
| Templates | HAML |
| Data | SPARQL endpoint queried via the `data_services_api` gem |
| Error tracking | Sentry |
| Logging | Structured JSON via the `epilog_rails` gem |
| Metrics | Prometheus (`prometheus-client`, `puma-metrics`) |
| E2E testing | Node 24 + Yarn 4 + Playwright (Chromium) |

This is a server-rendered Rails application with no Node.js build tooling — there is
no Vite and no Webpack. Node is present **only** to run Playwright E2E automations;
it plays no part in the application build or asset pipeline.

## Developer setup

### 1. Install Ruby

Use [rbenv](https://github.com/rbenv/rbenv) or [asdf](https://asdf-vm.com) to install
the version pinned in `.ruby-version` (currently `3.4.9`).

With rbenv:

```bash
rbenv install        # reads .ruby-version automatically
gem install bundler
```

### 2. Authenticate with the private gem registry

The `data_services_api`, `epilog_rails`, and `lr_common_styles` gems are hosted
on the Epimorphics GitHub Package Registry. You need a GitHub Personal Access Token
with the `read:packages` scope.

Configure Bundler with your token:

```bash
./bin/bundle config set --local rubygems.pkg.github.com epimorphics:<your-token>
```

### 3. Install dependencies

```bash
./bin/bundle install
```

No Node or Yarn installation is required to run or build the application. Node is
only needed if you intend to run Playwright E2E tests — see [E2E testing](#e2e-testing).

### 4. Environment variables

`.env.development` contains sensible defaults for local development and is checked
in — no copying required. The app will start without any further configuration.

To override a value, create `.env.local` and set it there — Rails loads `.env.local`
first and falls back to `.env.development`. `.env.local` is gitignored.

| Variable | Default | Purpose |
|---|---|---|
| `API_SERVICE_URL` | `http://localhost:8888` | Backing SPARQL/data API |
| `PORT` | `3001` | Rails server port |
| `METRICS_PORT` | `9394` | Prometheus metrics port |
| `SENTRY_ENABLED` | `false` | Enable Sentry error tracking |
| `SENTRY_AUTH_TOKEN` | — | Required only for production builds (source map upload) |
| `SENTRY_API_KEY` | — | Required only if `SENTRY_ENABLED=true` |

## Data API

The app queries a backing data API at `API_SERVICE_URL` (default
`http://localhost:8888`). To run it locally, install Maven and follow the
instructions in the
[lr-data-api](https://github.com/epimorphics/lr-data-api) repository, ensuring
it listens on port `8888`.

## Running locally

```bash
./bin/rails server -p 3001
```

The app is served on port 3001 by default and expects a data API at `API_SERVICE_URL`
(see `.env.development`).

## Testing

```bash
./bin/rails test
```

Tests use VCR cassettes under `test/vcr_cassettes/`. To discard cassettes and force
live HTTP calls on the next run:

```bash
rm test/vcr_cassettes/*
```

View the coverage report after a test run:

```bash
open coverage/index.html
```

## E2E testing

Playwright is used for end-to-end browser automation. Node is required only for this:
it is not used in the application build.

**Prerequisites:** Node 24 via [nvm](https://github.com/nvm-sh/nvm):

```bash
nvm install   # reads .nvmrc automatically
nvm use
```

**Install dependencies** (yarn resolves from `.yarn/releases/yarn-4.14.1.cjs` via
`yarnPath` in `.yarnrc.yml` — no separate corepack step needed):

```bash
yarn install
```

**Run against the local server** (starts Rails automatically on port 3001):

```bash
yarn test:e2e
```

**Interactive UI mode:**

```bash
yarn test:e2e:ui
```

**Open the last HTML report:**

```bash
yarn test:e2e:report
```

### Running against a deployed environment

Set `E2E_BASE_URL` to any URL from [Environments](#environments). For
pre-production, also pass the Basic Auth [credentials](#credentials):

```bash
E2E_BASE_URL=https://hmlr-preprod-pres.epimorphics.net/app/ppd/ \
E2E_USERNAME=user \
E2E_PASSWORD=secret \
yarn test:e2e
```

### In CI

The **E2E Tests** workflow (`.github/workflows/e2e.yml`) is manual only: run it
from **Actions > E2E Tests > Run workflow**. It always targets pre-production.
The dev hosts are too small to complete some of the large queries the suite
makes, so runs against dev fail for reasons unrelated to the code.

## Linting

```bash
./bin/bundle exec rubocop -a    # Ruby — auto-corrects safe offences
```

**JavaScript (Playwright tests):**

```bash
yarn lint          # ESLint — check Playwright config and test files
yarn lint:fix      # ESLint — auto-fix safe offences
```

There is no HAML linting.

## Building and publishing

> [!WARNING]
> Do not trigger deployments concurrently. ukhpi, ppd-explorer,
> standard-reports-ui and lr-landing all deploy to the same hosts with the
> same Ansible playbook, and nothing stops two deploys from overlapping. Before
> pushing to `dev`, `preprod` or `prod`, check the Actions tab of all four
> repositories and wait for any deploy in progress to finish.

The `Makefile` is scoped to the Docker image build and publish pipeline.

```bash
make image     # Build the Docker image (requires GitHub token configured)
make publish   # Push to AWS ECR
make vars      # Print all build variables
make tag       # Print the computed image tag
make version   # Print the application version
```

Variables can be overridden on the command line, e.g.:

```bash
STAGE=preprod make publish
```

Branch-to-environment mapping is defined in `deployment.yaml`. CI runs
`publish` and `deploy` automatically on push via
`.github/workflows/publish-deploy.yml`.

## Releases

Releases follow the [Frontend Release Process](https://github.com/epimorphics/internal/wiki/Release-Process-Frontend).

The canonical version file is `app/lib/version.rb`. The changelog is maintained in `CHANGELOG.md`.

Environment branches are kept as strict fast-forward pointers to tagged commits on `dev`. URLs for each environment are listed under [Environments](#environments).

## Environments

| Branch | Environment | URL | Basic Auth |
|--------|-------------|-----|------------|
| `dev` | Dev | https://hmlr-dev-pres.epimorphics.net/app/ppd/ | No |
| `preprod` | Pre-production | https://hmlr-preprod-pres.epimorphics.net/app/ppd/ | Yes |
| `prod` | Production | https://landregistry.data.gov.uk/app/ppd/ | No |

Pushing to an environment branch builds, publishes and deploys to that
environment (see [Building and publishing](#building-and-publishing)).

### Credentials

Pre-production is protected by HTTP Basic Auth. The credentials are not stored
in this repository: ask Ops for them. The E2E workflow reads the same
credentials from the `E2E_USERNAME` and `E2E_PASSWORD` repository secrets.

## Observability

Metrics for the presentation hosts of all HMLR apps are in
[Grafana](https://grafana-hmlr.epimorphics.net/). Use it to see how each
environment has behaved over time and to line up a problem with when it
started. Ask Ops for access.

### Logging

Logs are single-line JSON on stdout, formatted by
[`epilog_rails`](https://github.com/epimorphics/epilog-rails) to the
[logging standard](https://github.com/epimorphics/internal/wiki/Logging-Standard).
The gem logs every request itself, so controllers and models must not: each
request produces one `received` entry and one `completed` entry (or `error` for a
5xx), sharing a `request_id` and carrying `method`, `path`, `status` and
`request_time` in seconds.

To log something else, pass `Rails.logger` a string or a Hash with a `message`
key. Never pass it `JSON.generate(...)` or `to_json`: the formatter encodes the
entry, so pre-encoded text ends up as JSON inside the `message` string.

In the test environment logs go to `log/test.log`, not stdout.

Calls to the Data Services API are logged by `ApiRequestLogSubscriber`, from the
events the `data_services_api` gem emits: one entry when a call is made, one when
it returns (with `returned_rows`, `status` and `request_time`), a `WARN` before
each retry, and one `ERROR` if it fails. Models and controllers must not log API
calls themselves.

### Error handling

Controllers do not rescue errors or render error pages. An exception propagates
to Rails, which maps it to a status and renders the page through
`ErrorsController` (`config.exceptions_app` in `config/application.rb`):

- An unmatched path is a 404.
- A `MalformedSearchError` (a search term, date or price that cannot be used) is a
  400, and its message is shown on the page. To make another error a deliberate
  status, give it its own exception class and register it in
  `config.action_dispatch.rescue_responses`.
- A failure of the Data Services API is left to propagate from the
  `data_services_api` gem, not rescued: 503 if it cannot be reached, 504 if it does
  not answer in time, 502 if it answers with an error. The page advises the user to
  narrow the search. These are counted by the `api_*` metrics below.
- Anything else is a 500. It is reported to Sentry and increments the
  `internal_application_error` metric.

HTML requests get the error page; CSV and Turtle requests get the status text as
plain text. In development Rails shows its debug page instead.

Tests run with `show_exceptions = :none`, so an unexpected exception fails the test
with a backtrace. Tests of the error pages themselves call `render_error_pages`
(see `test/integration/error_handling_test.rb`) and must assert on the status as
well as the body.

### Metrics

`/metrics` is served by the Prometheus middleware. Alert rules are kept by Ops, not
in this repository, so a change to a metric's name or labels must be agreed with
them for the same deploy.

Label values are bounded: they never contain an exception's own message, which can
carry user input or a URL and would create a new time series per value.

| Metric | Labels | Counts |
|---|---|---|
| `internal_application_error` | `message`: `Unhandled <exception class> in <controller>#<action>`, e.g. `Unhandled NoMethodError in search#index` | Responses with status 500 |
| `api_requests` | `result`: `success` or `failure` | Every Data Services API call |
| `api_status` | `status`: the HTTP status | API calls that returned a response |
| `api_response_times` | none (histogram, milliseconds) | API calls that returned a response |
| `api_connection_failure` | `message`: the exception class, `Faraday::ConnectionFailed` or `Faraday::TimeoutError` | API calls that got no response, after retries |
| `api_service_exception` | `message`: `HTTP <status>`, e.g. `HTTP 503`, or `no response status` | API calls that got an error response |

These are recorded by the subscribers in `app/subscribers/`, which listen for the
`data_services_api` gem's `*.data_services_api` events. If a gem upgrade renames
those events the subscribers receive nothing and the metrics stop without any
error; `test/integration/api_failure_test.rb` exists to catch that.

## Dependency maintenance

```bash
./bin/bundle update --patch              # Update all gems to latest patch version
./bin/bundle outdated --only-explicit    # Check for outdated gems
```

### Upgrading Rails

Bumping the `rails` gem is not enough: a new Rails version only changes behaviour
once the app opts in to that version's framework defaults. On every Rails upgrade
(minor or major):

1. Run `./bin/rails app:update` and review each proposed change with `git diff`.
   Keep what is relevant and restore anything that overwrites app-specific
   configuration (most of `config/` and `bin/`).
2. Turn on the new defaults a few at a time in the generated
   `config/initializers/new_framework_defaults_X_Y.rb`, running the tests and
   comparing response headers (`curl -I`) as you go.
3. When they are all on, set `config.load_defaults X.Y` in `config/application.rb`
   and delete the initializer.
