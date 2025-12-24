
Feature: retrieve PPD data downloads

  As a visitor

  I want to retrieve and read the PPD datasets page

  In order to be able to download PPD monthly datasets

  Scenario:
    Given I am a visitor
    When I retrieve the page "/ppd-data.html"
    Then I should retrieve a web page
    And it should have the title "Download Price Paid Data"
    And it should have content "Price paid data download options"



