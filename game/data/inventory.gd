
const items = [
	{ "id": "cathair", "title": "Hair", "points": 10, "description": "Some hair I found where the amulet was last seen", "icon": "res://scenes/test/Cat_Hair.png"},
	{ "id": "money", "title": "Money", "description": "Some money I found on the floor", "icon": "res://scenes/test/Money.png"},
	{ "id": "map", "title": "Map", "description": "A mysterious map" },
	{ "id": "berries", "title": "Berries", "description": "Red berries, the guide says they're safe to eat.", "icon": "res://scenes/test/Bush_Berries.png"},
	{ "id": "office1", "title": "Office1", "description": "Found some lemon things in his desk.", "icon": "res://scenes/test/Money.png"},
	{ "id": "office2", "title": "Office2", "description": "Found performance reports", "icon": "res://scenes/test/Money.png"},
	{ "id": "kitchen1", "title": "kitchen1", "description": "Coffee in sink", "icon": "res://scenes/test/Money.png"},
	{ "id": "kitchen2", "title": "kitchen2", "description": "Cookie crumbs", "icon": "res://scenes/test/Money.png"}
]

const clues = [
	#UI testing facts
	{ "id": "checkers_work_for_Fat_Cat", "title": "Checkers is an associate of the dastardly Fat Cat!" },
	{ "id": "checkers_is_cat", "title": "The suspect, Checkers, is a black cat" },
	{ "id": "all_cats_work_for_Fat_Cat", "title": "All cats work for Fat Cat" },
	{ "id": "password", "title": "Map Vendor Password", "description": "The map vendor needs a password. I could try the one from Monkey Island" },
	{ "id": "monkey_island", "title": "His favorite game is Monkey Island", "description": "The Map Vendor's favorite game is Monkey Island" },
	{ "id": "found_employee_badge", "title" : "We found an employee badge reading: 'Checkers the Cat, associate of Fat Cat'" },
	{ "id": "employee_badge_no_pic", "title": "The employee badge doesn't have a picture or ID, not sure if it's legit." },
	{ "id": "test", "title": "test 1" },
	{ "id": "test1", "title": "test 2" },
	{ "id": "tier3_test", "title": "Test for 3rd tier" },
	{ "id": "tier3_test2", "title": "Test for 3rd tier (CHILD)" },
	
	#Scenario 0 facts	
	{ "id": "general2", "title": "Everyone who was in the kitchen from 4PM to 4:30PM is a suspect." },
	{ "id": "general3", "title": "Bee could have taken the cookies." },
	{ "id": "general4", "title": "Archie himself could have hidden the cookies between 4PM and 4:05PM, when he stepped out of the office." },
	{ "id": "general5", "title": "Eyy could have taken the cookies." },
	{ "id": "general7", "title": "Someone could be trying to sabotage Eyy with lemon fairies." },
	{ "id": "general9", "title": "Bee could be trying to sabotage Eyy with lemon fairies." },

	{ "id" : "me1", "title": "YOU could have stolen the cookies, though you have no memory of doing so." },
	{ "id": "library4", "title": "There are nefarious lemon fairies that are attracted by anything that looks, smells or tastes like lemons." },
	{ "id": "kitchen1", "title": "There is brown liquid and there are traces of coffee grounds in the sink." },

	{ "id": "archie1", "title": "Archie went to the kitchen at 4PM, left his plate and cookies, then returned to his office around 4:05PM." },
	{ "id": "archie3", "title": "Archie noticed the cookies and plate were gone at 4:30PM." },
	{ "id": "archie4", "title": "Archie saw Bee in the kitchen at 4PM. He didn't notice anyone else."},
	{ "id": "archie6", "title": "You and Archie were in his office talking from 4:05PM until 4:30PM." },

	{ "id": "eyy1", "title": "Eyy went to the break room sometime after 4PM and saw Archie on his way there." },
	{ "id": "eyy2", "title": "While in the break room, Eyy took a handful of cookies, made tea, and went back to his desk, where he continued working until you spoke to him." },
	{ "id": "eyy6", "title": "While taking a cookie, Eyy saw Bee near the sink. She was still there when he left."},

	{ "id": "bee1", "title": "Bee was in the break room at 4PM, washing her coffee mug in the sink." },
	{ "id": "bee2", "title": "Bee saw Eyy walk in the break room and take a cookie." },
	{ "id": "bee3", "title": "Bee left the break room soon after Eyy arrived, around ~4:05PM. He was alone in the kitchen." },

	{ "id": "office1", "title" : "Lemon paraphernalia in A's desk" },
	{ "id": "office2", "title" : "Squash Squad Performance Report: 1) A, 2) XXX, 3) YYY, 4) Bee" },
]