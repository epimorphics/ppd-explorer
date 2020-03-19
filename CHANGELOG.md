# HMLR PPD explorer

This app allows the user to explore HMLR price-paid open
linked data.

## 1.2.1 - 2020-03-19

- Update some dependent gems to resolve CVE warnings, but keep
  Rails at version 5.

## 1.2.0 - 2019-12-17

- Changed minor version number as we've switched to using a
  separate Sentry project for this app.

## 1.1.3 - 2019-12-09

- Add `ActionController::BadRequest` to the list of ignored
  exceptions for Sentry
- Fix method name clash with `ApplicationController.render_error`
  and `SearchController.render_error` leading to Sentry warning

## 2019-11-15

- Updated README
- skipped some tests that are blocking due to chromedriver
  (see GH-101)
- fix rubocop warnings
- update the log files to write more structured information
  that will help with diagnosing intrusively slow queries
  (GH-97)

## 2019-07-17

- (Belatedly) added a change log
- Update gem dependencies
