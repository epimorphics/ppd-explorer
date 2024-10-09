# HMLR PPD explorer

This app allows the user to explore HMLR price-paid open linked data.

## Changelog

## 1.7.10 - 2024-10

- (Jon) Updated the message reported to the error page while in development mode
  to include the error message and the status code; also configured the helper
  to display the actual rails stack trace in development mode
- (Jon) Added the `log_error` helper to the `render_error_page` helper method in
  the `search_controller` to apply the appropriate log level based on the status
  code
- (Jon) Added `RoutingError` and `MissingTemplate` to the list of exceptions to
  be caught by the `render_error_page` helper method in the `search_controller`
- (Jon) Wrapped the Internal Error Instrumentation in an `unless` block to
  ensure the application does not report internal errors to the Prometheus
  metrics when the error is a 404 or 422 thereby reducing the noise in the Slack
  alerts channel

## 1.7.9 - 2024-09

- (Jon) Updated the application exceptions controller to instrument the
  `ActiveSupport::Notifications` for internal errors
  [GH-244](https://github.com/epimorphics/ppd-explorer/issues/244)
- (Jon) Updated `config/initializers/prometheus.rb` to include the `Middleware
  instrumentation` fix for the 0 memory bug by notifying Action Dispatch
  subscribers on Prometheus initialise
  [GH-244](https://github.com/epimorphics/ppd-explorer/issues/244)
- (Jon) Updated `config/puma.rb` to include metrics plugin and port information
  for the metrics endpoint as environment variable, with default, to enable
  running multiple sibling HMLR apps locally if needed without port conflicts
  [GH-244](https://github.com/epimorphics/ppd-explorer/issues/244)
- (Jon) Updated the `lr_common_styles` gem to the latest 1.9.9 patch release.
- (Jon) Moved all mirrored configuration settings from individual environments
  into the application configuration to reduce the need to manage multiple
  sources of truth
- (Jon) Implemented improved boilerplate metrics integration to offer analysis
  of current application usage stats
- (Jon) Additional metrics from the Puma server to be exposed in the /metrics
  endpoint via the puma-metrics gem
- (Jon) Tweaked the application controller to improve error handling and
  ensuring additional filtering for specific errors completes when able
- (Jon) Reorganised makefile targets alphabetically as well as mirrored other
  improvements from the other applications in the suite
- (Jon) Updated .gitignore file to mirror the current approach in the other HMLR
  apps
- (Jon) Updated .rubocop.yml file with rules to reduce the need to set overrides
  inline
- (Jon) Updated the `lr_common_styles` gem to the latest 1.9.6 patch release.
- (Dan) Fixes the bug search results not displaying
  [232](https://github.com/epimorphics/ppd-explorer/issues/232)
- (Dan) Adds page titles to download page and error page. Improves code dryness
  [220](https://github.com/epimorphics/ppd-explorer/issues/220)
- (Dan) Updates gemfile to use v1.9.5 lr_common_styles
- (Dan) Adds more descriptive page titles
  [220](https://github.com/epimorphics/ppd-explorer/issues/220)
- (Dan) Adds search actions buttons to the top of the page
  [226](https://github.com/epimorphics/ppd-explorer/issues/226)
- (Dan) Increases target size of clickable elements to meet accessibility
  requirments [GH-225](https://github.com/epimorphics/ppd-explorer/issues/225)
- (Dan) updates the search results modal focus flow to meet accessibility
  requirments [GH-216](https://github.com/epimorphics/ppd-explorer/issues/216)
- (Dan) updates the form to meet various accessibility requirments
  [GH-217](https://github.com/epimorphics/ppd-explorer/issues/217)
- (Dan) updates the help modal focus flow to meet accessibility requirments
  [GH-218](https://github.com/epimorphics/ppd-explorer/issues/218)

## 1.7.8 - 2024-09

- (Jon) Updated the type check for the current search terms to only sanitise
  strings and pass other types, i.e. Date, Integer, as is.
  [GH-245](https://github.com/epimorphics/ppd-explorer/issues/245)

## 1.7.7 - 2024-09

- (Jon) Updated search query processing and rendering to santise supplied input
  for HTML output and resolve discovered XSS vulnerability in displayed results
  [GH-236](https://github.com/epimorphics/hmlr-linked-data/issues/236)

## 1.7.6 - 2024-03-08

- (Jon) Updated the application_controller to include an
  `ActionView::MissingTemplate` rescue to ensure the correct 404 template is
  displayed when a template is not found
  [GH-138](https://github.com/epimorphics/hmlr-linked-data/issues/138)

## 1.7.5 - 2023-11-27

- (Jon) Updated the `lr_common_styles` gem to the latest 1.9.3 patch release.

## 1.7.4 - 2023-11-23

- (Jon) Updated the `lr_common_styles` gem to the latest 1.9.2 patch release.
  - Also includes minor patch updates for gems, please see the `Gemfile.lock`
  for details.

## 1.7.3.1 - 2023-07-11

- (Jon) Updated the `app/controllers/application_controller.rb` to include the
  `before_action` for the `change_default_caching_policy` method to ensure the
  default `Cache-Control` header for all requests is set to 5 minutes (300
  seconds).

## 1.7.3 - 2023-06-07

- (Jon) Updated the `json_rails_logger` gem to the latest 1.0.1 patchrelease.
  - Also includes minor patch updates for gems, please see the `Gemfile.lock`
  for details.
- (Jon) Commented out the printing instructions on the help modal dialog
  [GH-191](https://github.com/epimorphics/ppd-explorer/issues/191)
- (Jon) Resolves un-decoded html entities in search term labels

## 1.7.2 - 2023-06-03

- (Jon) Updated the `json_rails_logger` gem to the latest 1.0.0 release.

## 1.7.1 - 2023-03-10

- (Jon) Added the updated configuration for the AWS credential improvements as
  per other readme's; included further info to run the application locally;
  resolved a markdown linting issue with using HTML in markdown.
- (Jon) Refactors the elapsed time calculated for API requests to be resolved as
  microseconds rather than milliseconds. This is to improve the reporting of the
  elapsed time in the system tooling logs.
- (Jon) Minor text changes to the `Gemfile` to include instructions for running
  Epimorphics specific gems locally during the development of those gems.
- (Jon) Updated the production `data_services_api` gem version to be at least
  the current version`~>1.3.3` (this is to cover out of sync release versions)
- (Jon) Updated the production `json_rails_logger` gem version to be at least
  the current version `~>1.3.5` (this is to cover out of sync release versions)
- (Jon) Updated the production `lr_common_styles` gem version to be at least the
  current version `~>1.9.1` (this is to cover out of sync release versions)
- (Jon) Refactored better guards in `entrypoint.sh` to ensure the required env
  vars are set accordingly or deployment will fail noisily.
- (Jon) Refactored the error messages displayed to be semantically formatted as
  well as incorporated ALL lines for the returned message to be held in the
  variable instead of being possibly displayed outside of the intended context.
- (Jon) Refactored the version cadence creation to include a SUFFIX value if
  provided; otherwise no SUFFIX is included in the version number.
- (Jon) Adjusted the processing of error status to use the application template;
  also includes adjustments to not double render the error response.

## 1.7.0 - 2022-04-07

- (Ian) Adopt all of the current Epimorphics best-practice deployment patterns,
  including shared GitHub actions, updated Makefile and Dockerfile, Prometheus
  monitoring, and updated version of Sentry.
- (Ian) Updated the README as part of handover.

## 1.6.1 - 2022-03-22

- (Ian) Switch to using local gems from GitHub Package Registry
- (Ian) Update Prometheus metric to follow local best practice
- (Ian) Ensure Rails and Puma startup messages log as JSON

## 1.6.0 - 2022-01-31

- (Ian) Added Prometheus metrics for observability in production

## 1.5.1 - 2022-01-28

- (Joseph) Change to as SPARQL query redirect url

## 1.5.0 - 2022-01-10

- (Mairead) Update deployment workflow, dockerfile and assisting scripts
- (Mairead) Add locality to search fields
- (Ian) unify `dev` and `dev-infra` branches in 1.5.0 release

## 1.4.4 - 2021-06-25

- (Joseph) Small config change to allow linking to privacy notice.

## 1.4.3 - 2021-04-27

- (Ian) Updated correction to email address (GH-3)

## 1.4.2 - 2020-03-01

- (Ian) Gem update, fix rubocop warnings
- (Ian) Switch from Travis to Github Actions for CI

## 1.4.1 - 2020-09-22 (Ian)

- added accessibility statement

## 1.4.0 - 2020-09-22 (Ian)

- switched from JQuery datePicker component to use browser date input controls

## 1.3.1 - 2020-09-22 (Ian)

- added a skip-to-main-content link for keyboard navigation

## 1.3.0 - 2020-09-20 (Ian)

- A collection of WCAG fixes under GH-117. Pending manual testing, this should
  bring the app into WCAG compliance

## 1.2.2 - 2020-07-06

- Update gem dependencies following CVE warnings

## 1.2.1 - 2020-03-19

- Update some dependent gems to resolve CVE warnings, but keep Rails at version
  5.

## 1.2.0 - 2019-12-17

- Changed minor version number as we've switched to using a separate Sentry
  project for this app.

## 1.1.3 - 2019-12-09

- Add `ActionController::BadRequest` to the list of ignored exceptions for
  Sentry
- Fix method name clash with `ApplicationController.render_error` and
  `SearchController.render_error` leading to Sentry warning

## 2019-11-15

- Updated README
- skipped some tests that are blocking due to chromedriver (see GH-101)
- fix rubocop warnings
- update the log files to write more structured information that will help with
  diagnosing intrusively slow queries (GH-97)

## 2019-07-17

- (Belatedly) added a change log
- Update gem dependencies
