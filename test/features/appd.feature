Feature: retrieve home page

	As a visitor

	I want to retrieve additional price paid data information

    @javascript
    Scenario:
        Given I am a visitor
        When I retrieve the page "/app/ppd"
        And I enter "AL7 1AJ" in the "postcode" field
        And I click on the "detached" checkbox
        And I click on the "semi-detached" checkbox
        And I click on the "terraced" checkbox
        And I click on the "flat/maisonette" checkbox
        And I choose the "all" radio button
        And I click on the "show results" button
        Then I should retrieve a web page
        And it should have content "8 Brownfields Court, Welwyn Garden City, AL7 1AJ"

    @javascript
    Scenario:
        Given I am a visitor
        When I retrieve the page "/app/ppd"
        And I enter "AL7 1BX" in the "postcode" field
        And I click on the "other" checkbox
        And I choose the "all" radio button
        And I click on the "show results" button
        Then I should retrieve a web page
        And it should have content "1 The Swallows, Welwyn Garden City, AL7 1BX"
