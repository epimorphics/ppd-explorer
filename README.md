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
- [Dependency maintenance](#dependency-maintenance)

## Tech stack

| Layer | Technology |
|---|---|
| Backend | Ruby on Rails 8.1, served via Puma |
| Assets | Sprockets asset pipeline + Dart Sass |
| Templates | HAML |
| Data | SPARQL endpoint queried via the `data_services_api` gem |
| Error tracking | Sentry |
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

The `data_services_api`, `json_rails_logger`, and `lr_common_styles` gems are hosted
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

Playwright is used for end-to-end browser automation. Node is required only for this
— it is not used in the application build.

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

**Run against a remote environment:**

```bash
E2E_BASE_URL=https://staging.example.com yarn test:e2e
```

Optional HTTP basic auth for protected environments:

```bash
E2E_BASE_URL=https://staging.example.com \
E2E_USERNAME=user \
E2E_PASSWORD=secret \
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

The CI workflow (`.github/workflows/e2e.yml`) is `workflow_dispatch` only — it does
not run automatically on push. Trigger it manually from the Actions tab, supplying the
target URL.

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

Branch-to-environment mapping is defined in `deployment.yaml`. CI runs `publish` and
`deploy` automatically on push via `.github/workflows/publish-deploy.yml`.

## Releases

Releases follow the [Frontend Release Process](https://github.com/epimorphics/internal/wiki/Release-Process-Frontend).

| Branch | Environment | URL |
|--------|-------------|-----|
| `dev` | Dev | https://hmlr-dev-pres.epimorphics.net/app/ppd/ |
| `preprod` | Pre-production | https://hmlr-preprod-pres.epimorphics.net/app/ppd/ |
| `prod` | Production | https://landregistry.data.gov.uk/app/ppd/ |

The canonical version file is `app/lib/version.rb`. The changelog is maintained in `CHANGELOG.md`.

Environment branches are kept as strict fast-forward pointers to tagged commits on `dev`. Branch-to-environment mapping is also declared in `deployment.yaml`.

## Dependency maintenance

```bash
./bin/bundle update --patch              # Update all gems to latest patch version
./bin/bundle outdated --only-explicit    # Check for outdated gems
```
