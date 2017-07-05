func _ready():
	return
	
#This should contain created_relations["CLUEID"]["children"] will give children (curr node affects
#a child's score), and ...["parents"] will give parents (the nodes that affect curr's score)
var created_relations = {
	"default_clue" : { "parents" : ["default_parent"], "children" : ["default_child"] },
}

#When checking the relations of two facts, 
#	input: fact_relations["CLUEID"]["AND"/"CONTRADICTS"/"SUPPORTS"]["clues"]
#Example: fact_relations["CLUEID"]["AND"]["clues"] gives one or more valid clues for that relation
#       Then, fact_relations["CLUEID"]["points"] gives the feasability points for that clue
#		Finally, factRelations["CLUEID"]["AND"]["result"] gives a resultant fact for "AND"
#If clue not found in "clues" array for a relation, give default response.
const fact_relations = {
	"all_cats_work_for_Fat_Cat" : {
		"and": { "clues" : ["checkers_is_cat"],
		"result" :"checkers_work_for_Fat_Cat" },
		"points" : 60 },
	"checkers_is_cat" : {
		"and" : { "clues" : ["all_cats_work_for_Fat_Cat"],
		"result" : "checkers_work_for_Fat_Cat" },
	"checkers_work_for_Fat_Cat" : {
	},
	"employee_badge_no_pic" : {
		"contradicts": { "clues" : ["checkers_work_for_Fat_Cat"]},
		"points" : 50
	},
	"found_employee_badge" : {
		"supports" : { "clues" : ["checkers_work_for_Fat_Cat"]},
		"points" : 100
	}
}

const default = "This doesn't make sense to me..."
