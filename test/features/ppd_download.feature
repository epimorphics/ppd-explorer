Feature: download ppd data

	As a visitor

	I want to retrieve information about the house price index for a region

	@javascript
	Scenario:
		Given I am a visitor
		When I retrieve the page "/app/ppd"
		And I enter "exeter" in the "town" field
		And I click on the "show results" button
		Then I should retrieve a web page
		And I click on the first "download data" button
		Then I should retrieve a web page
    And it should have link text "get selected results as CSV with headers" with link ending with ".csv"
