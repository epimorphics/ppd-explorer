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
- [Releasing](#releasing)
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

## Releasing

This repository uses long-lived environment branches (`preprod`, `prod`) that are kept
as strict fast-forward pointers to tagged commits on `dev`. CI deploys automatically
on push, so promoting an environment is a case of fast-forwarding its branch and
pushing.

**Key invariant:** environment branches always point to a tagged commit on `dev`'s
linear history. Direct pushes to environment branches are not permitted.

### Standard release

**1. Finish work on `dev`**

Merge all feature branches into `dev` and ensure CI passes.

**2. Bump the version and update the changelog**

Edit `app/lib/version.rb` and `CHANGELOG.md`, then commit and push to `dev`:

```bash
git add app/lib/version.rb CHANGELOG.md
git commit -m "chore: release vx.y.z"
git push origin dev
```

**3. Tag the release commit**

```bash
git tag vx.y.z
git push origin vx.y.z
```

**4. Promote each environment branch in turn**

Fast-forward `preprod` first, verify the deployment, then repeat for `prod`:

```bash
git checkout preprod
git merge --ff-only vx.y.z
git push origin preprod
```

CI triggers automatically on push. Verify before promoting the next environment. If
`--ff-only` is refused, the branch has diverged — investigate before proceeding.

```bash
git checkout prod
git merge --ff-only vx.y.z
git push origin prod
```

**5. Optionally create a GitHub release**

Go to **Releases** on the repository page, draft a new release from the tag, and
publish.

---

### Hotfix release

**1. Branch off the current production tag**

```bash
git checkout -b hotfix/vx.y.z vx.y.(z-1)
```

**2. Make the fix, tag it, and push**

```bash
git add <files>
git commit -m "fix: <description>"
git tag vx.y.z
git push origin hotfix/vx.y.z vx.y.z
```

**3. Bring the fix into `dev`**

Preferred — rebase:

```bash
git rebase hotfix/vx.y.z dev
git push --force-with-lease origin dev
```

Safe fallback — cherry-pick:

```bash
git checkout dev
git cherry-pick vx.y.z
git push origin dev
```

**4. Promote environment branches to the hotfix tag**

Same as a standard release — fast-forward `preprod` then `prod`, verifying each
before moving to the next.

**5. Clean up the hotfix branch**

```bash
git branch -d hotfix/vx.y.z
git push origin --delete hotfix/vx.y.z
```

## Dependency maintenance

```bash
./bin/bundle update --patch              # Update all gems to latest patch version
./bin/bundle outdated --only-explicit    # Check for outdated gems
```
