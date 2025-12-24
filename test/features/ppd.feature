Feature: ppd

	As a visitor

	I want to retrieve information about the price paid for houses

    @javascript
    Scenario:
      Given I am a visitor
      When I retrieve the page "/app/ppd"
      Then I should retrieve a web page
      And it should have rules from stylesheet matching ".*application.*\.css$"
      And it should have an image matching "lr_logo.*\.png$"b

    @javascript
    Scenario:
      Given I am a visitor
      When I retrieve the page "/app/ppd"
      And I enter "plymouth" in the "town" field
      And I click on the "not new-build" checkbox
      And I enter "1 Apr 2014" in the "min_date" field
      And I enter "30 Apr 2014" in the "max_date" field
      And I choose the "all" radio button
      And I click on the "show results" button
      Then I should retrieve a web page
      And it should have content "5 Falcon Road, Plymouth, PL1 4GR"
      And it should have content "69 Millbay Road, Plymouth, PL1 3NG"
      And it should have content "71 Millbay Road, Plymouth, PL1 3NG"
      And it should have content "Flat 9, 15 Ridge Park Road, Plymouth, PL7 2FG"
      And it should have content "3 Verden Close, Plymouth, PL3 4BT"
      And it should have content "7 Gardeners Lane, Plymouth, PL8 2PJ"
      And it should have content "10 Gardeners Lane, Plymouth, PL8 2PJ"


    @javascript
    Scenario:
      Given I am a visitor
      When I retrieve the page "/app/ppd"
      And I enter "adam and eve mews" in the "street" field
      And I choose the "all" radio button
      And I click on the "show results" button
      Then I should retrieve a web page
      And it should have content "5 Adam & Eve Mews, London, W8 6UG"
