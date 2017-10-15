func _ready():
	return
	
#This should contain created_relations["CLUEID"]["children"] will give children (curr node affects
#a child's score), and ...["parents"] will give parents (the nodes that affect curr's score)
var created_relations = {
}

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
	"general1" : {
		"points" : 100
	},
	"general2" : {
		"and" : { "clues" : ["bee1", "archie4", "archie6", "eyy1", "bee2"],
		"result" : ["general3", "general3", "general4", "general5", "general5"]},
		"points" : 100
	},
	"archie1" : { 
		"and" : { "clues" : ["archie3"],
		"result" : ["general2"]},
		"points" : 90
	},
	"archie2" : { 
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
		"points" : 90
	},
	"archie5" : {
		"contradicts" : { "clues" : ["general4"] },
		"and" : { "clues" : ["general7"],
		"result" : ["general8"] },
		"points" : 99
	},
	"archie6" : {
		"and" : { "clues" : ["general2", "general8"],
		"result" : ["general4", "general9"] },
		"points" : 99
	},
	"bee1" : { 
		"supports" : { "clues" : ["archie4"] },
		"and" : { "clues" : ["general2"],
		"result" : ["general3"]},
		"points" : 90
	},
	"bee2" : { 
		"supports" : { "clues" : ["eyy2"] },
		"contradicts" : { "clues" : ["general4"] },
		"and" : { "clues" : ["bee3", "general2", "eyy4"],
		"result" : ["eyy3", "general5", "bee5"] },
		"points" : 90
	},
	"bee3" : { 
		"and" : { "clues" : ["bee2"],
		"result" : ["eyy3"] },
		"points" : 90
	},
	"bee4" : {
		"contradicts" : { "clues" : ["general3"] },
		"points" : 90
	},
	"bee5" : {
		"supports" : { "clues" : ["general3"] },
		"points" : -1
	},
	"general3" : {
		"points" : -1
	},
	"general4" : {
		"points" : -1
	},
	"general5" : {
		"points" : -1
	},
	"general6" : {
		"and" : { "clues" : ["library1"],
		"result" : ["general7"]},
		"points" : -1
	},
	"general7" : {
		"and" : { "clues" : ["archie5", "office2"],
		"result" : ["general8", "general8"] },
		"contradicts" : { "clues" : ["general5"] },
		"points" : -1
	},
	"general8" : {
		"and" : { "clues" : ["archie6"],
		"result" : ["general9"] },
		"contradicts" : { "clues" : ["general5"] },
		"points" : -1
	},
	"general9" : {
		"supports" : { "clues" : ["general3"] },
		"contradicts" : { "clues" : ["general5"] },
		"points" : -1
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
	"library3" : {
		"points" : 5
	},
	"eyy1" : {
		"and" : { "clues" : ["general2"],
		"result" : ["general5"]},
		"contradicts" : { "clues" : ["general4"] },
		"supports" : { "clues" : ["archie1"] },
		"points" : 90
	},
	"eyy2" : {
		"supports" : { "clues" : ["bee2"] },
		"contradicts" :  { "clues" : ["general4"] },
		"points" : 90
	},
	"eyy3" : {
		"supports" : { "clues" : ["general5"]},
		"points" : -1
	},
	"eyy4" : { 
		"and" : { "clues" : ["bee2"],
		"result" : ["bee5"] },
		"contradicts" : {"clues" : [ "general5" ] },#"general4",, "eyy3"] },
		"points" : 90
	},
	"eyy5" : {
		"supports" : { "clues" : ["general7"] },
		"points" : 90
	},
	"kitchen1" : {
		"supports" : { "clues" : ["bee1"]},
		"points" : 99
	},
	"kitchen2" : {
		"supports" : { "clues" : ["eyy4"] },
		"points" : 99
	},
	"office1" : {
		"and" : { "clues" : ["secretary1"],
		"result" : ["general6"] },
		"supports" : { "clues" : ["general5"] },
		"points" : 99
	},
	"office2" : {
		"supports" : { "clues" : ["general9"]},
		"points" : 99
	},
	"secretary1" : {
		"and" : { "clues" : ["office1"],
		"result" : ["general6"] },
		"points" : 50
	},
}

const default = "This doesn't make sense to me..."
