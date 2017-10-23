func _ready():
	return
	
#This should contain created_relations["CLUEID"]["children"] will give children (curr node affects
#a child's score), and ...["parents"] will give parents (the nodes that affect curr's score)
var created_relations = {
}

const default = "This doesn't make sense to me..."

#When checking the relations of two facts, 
#	input: fact_relations["CLUEID"]["AND"/"CONTRADICTS"/"SUPPORTS"]["clues"]
#Example: fact_relations["CLUEID"]["AND"]["clues"] gives one or more valid clues for that relation
#       Then, fact_relations["CLUEID"]["points"] gives the feasability points for that clue
#		Finally, factRelations["CLUEID"]["AND"]["result"] gives a resultant fact for "AND"
#If clue not found in "clues" array for a relation, give default response.
var fact_relations = {
	"tier3_test" : {
		"and": { "clues": ["checkers_work_for_Fat_Cat"],
		"result" : "tier3_test2"},
		"points" : 1 },
	"tier3_test2" : {
		"points" : -1
	},
	"all_cats_work_for_Fat_Cat" : {
		"and": { "clues" : ["checkers_is_cat"],
		"result" :"checkers_work_for_Fat_Cat" },
		"points" : 60 },
	"checkers_is_cat" : {
		"and" : { "clues" : ["all_cats_work_for_Fat_Cat"],
		"result" : "checkers_work_for_Fat_Cat" },
		"points": 90 },
	"checkers_work_for_Fat_Cat" : {
		"points": -1
	},
	"employee_badge_no_pic" : {
		"contradicts": { "clues" : ["found_employee_badge"]},
		"points" : 50
	},
	"found_employee_badge" : {
		"supports" : { "clues" : ["checkers_work_for_Fat_Cat"]},
		"points" : 100
	},
	
	#Scenario 0 Relations
	"general2" : {
		"and" : { "clues" : ["bee1", "archie4", "archie6", "eyy1", "bee2"],
		"result" : ["general3", "general3", "general4", "general5", "general5"]},
		"points" : 100
	},
	"general3" : {
		"supports" : { "clues" : ["general9"] },
		"points" : -1
	},
	"general4" : {
		"points" : -1
	},
	"general5" : {
		"contradicts" : { "clues" : ["general7", "general9"] },
		"points" : -1
	},
	"general6" : {
		"and" : { "clues" : ["library1"],
		"result" : ["general7"]},
		"points" : -1
	},
	"general7" : {
		"and" : { "clues" : ["office2"],
		"result" : ["general9"] },
		"contradicts" : { "clues" : ["general5"] },
		"points" : -1
	},
	"general9" : {
		"supports" : { "clues" : ["general3"] },
		"contradicts" : { "clues" : ["general5"] },
		"points" : -1
	},

	"me1" : {
		"supports" : { "clues" : ["archie5"] },
		"points" : 100
	},

	"archie1" : { 
		"and" : { "clues" : ["archie3"],
		"result" : ["general2"]},
		"supports" : { "clues" : ["eyy1"] },
		"points" : 90
	},
	"archie3" : { 
		"and" : { "clues" : ["archie1"],
		"result" : ["general2"] },
		"points" : 90
	},
	"archie4" : { 
		"and" : { "clues": ["general2"],
		"result" : ["general3"] },
		"supports" : { "clues": ["bee1"] },
		"contradicts" : { "clues" : ["eyy1"] },
		"points" : 90
	},
	"archie5" : {
		"and" : { "clues": ["archie6"],
		"result" : ["archie7"] },
		"supports" : { "clues" : ["library2", "me1", "general3", "general4", "general5"] },
		"points" : 99
	},
	"archie6" : {
		"and" : { "clues" : ["general2", "general8"],
		"result" : ["general4", "general9"] },
		"points" : 99
	},
	"archie7" : {
		"contradicts" : { "clues" : ["me1", "general4"] },
		"supports" : { "clues" : ["general3", "general5"] },
		"points" : -1
	},

	"eyy1" : {
		"and" : { "clues" : ["general2"],
		"result" : ["general5"] },
		"supports" : { "clues" : ["archie1", "bee2"] },
		"points" : 90
	},
	"eyy2" : {
		"contradicts" : { "clues" : ["general4", "general5"] },
		"points" : 90
	},
	"eyy6" : {
		"supports" : { "clues" : ["archie4", "bee1"] },
		"contradicts" : { "clues" : ["bee3", "general5"] },
		"points" : 90
	},
	"library1" : {
		"and" : { "clues" : ["general6"],
		"result" : ["general7"]},
		"points" : 99
	},
	"library2" : {
		"supports" : { "clues" : ["archie5"] },
		"points" : 95
	},
	"library4" : {
		"and" : { "clues" : ["office1"],
		"result" : ["general6"] },
		"points" : 50
	},
	"kitchen1" : {
		"supports" : { "clues" : ["bee1"]},
		"points" : 99
	},
	"bee1" : { 
		"supports" : { "clues" : ["archie4"] },
		"and" : { "clues" : ["general2"],
		"result" : ["general3"]},
		"points" : 90
	},
	"bee2" : { 
		"supports" : { "clues" : ["eyy1"] },
		"contradicts" : { "clues" : ["general4"] },
		"and" : { "clues" : ["general2"],
		"result" : ["general5"] },
		"points" : 90
	},
	"bee3" : {
		"contradicts" : { "clues" : ["eyy6", "general3"] },
		"points" : 90
	},
	"office1" : {
		"and" : { "clues" : ["library4"],
		"result" : ["general6"] },
		"supports" : { "clues" : ["general5"] },
		"points" : 99
	},
	"office2" : {
		"and" : { "clues" : ["general7"],
		"result" : ["general9"] },
		"supports" : { "clues" : ["general9"]},
		"points" : 99
	},
}
