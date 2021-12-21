# HMLR PPD explorer

This app allows the user to explore HMLR price-paid open
linked data.

## 1.4.4 - 2021-12-15

- (Mairead) Update deployment workflow, dockerfile and assisting scripts

## 1.4.3 - 2021-04-27

- (Ian) Updated correction to email address (GH-3)

## 1.4.2 - 2020-03-01

- (Ian) Gem update, fix rubocop warnings
- (Ian) Switch from Travis to Github Actions for CI

## 1.4.1 - 2020-09-22 (Ian)

- added accessibility statement

## 1.4.0 - 2020-09-22 (Ian)

- switched from JQuery datePicker component to use browser date
  input controls

## 1.3.1 - 2020-09-22 (Ian)

- added a skip-to-main-content link for keyboard navigation

## 1.3.0 - 2020-09-20 (Ian)

- A collection of WCAG fixes under GH-117. Pending manual testing,
  this should bring the app into WCAG compliance

## 1.2.2 - 2020-07-06

- Update gem dependencies following CVE warnings

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
