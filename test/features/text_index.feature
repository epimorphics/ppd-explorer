Feature: text index

	As a visitor

	I want the text index to work properly when searching for data


	Scenario: common stop words not stopped and multiple search constraints work
		Given I am a visitor
		When I retrieve the page "/app/ppd"
		And I enter "plymouth" in the "town" field
		And I enter "the" in the "street" field
		And I enter "1 Apr 2014" in the "min_date" field
		And I enter "30 Apr 2014" in the "max_date" field
		And I choose the "all" radio button
		And I click on the "show results" button
		Then I should retrieve a web page
		And it should have content "1B The Dell, Plymouth, PL7 4PS"
		And it should have content "Basement, 2A The Esplanade, Plymouth, PL1 2PJ"


	@recent
	Scenario: common stop words not stopped and multiple search constraints work in recent data
		Given I am a visitor
		When I retrieve the page "/app/ppd"
		And I enter "the" in the "street" field
		And I specify the latest month for which data is available
		And I click on the "show results" button
		Then I should retrieve a web page
		And it should have at least one address




