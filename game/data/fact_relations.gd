func _ready():
	return

var created_relations = {
}

var clues_used_on_suspects = []

const SUSPECT_THRESHOLD = 90
const default = "This doesn't make sense to me..."
const supports = "This clue supports their guilt."
const contradicts = "This clue supports their innocence."
const found = "I already matched that clue to this suspect."
const no_puzzle = "I need to find more clues to analyze."
const puzzle_solved_success = "A-ha! I think I've solved this one."

var puzzles = {
	"puzzle1" : {
		"clues" : ["archie1", "archie2"],
		"solution" : 
			{ "therefore" : 1, "supports" : 0, "contradicts" : 0 },
		"is_solved" : false
	},
	"puzzle2" : {
		"clues" : ["general1", "archie3", "B1", "archie4", "A1"],
		"solution" : 
			{ "therefore" : 3, "supports" :  1, "contradicts" : 0},
		"is_solved" : false
	},
	"puzzle3" : {
		"clues" : ["library1", "office1", "office2"],
		"solution" : 
			{ "therefore" : 2, "supports" : 0, "contradicts" : 0 },
		"is_solved" : false
	}
}

var fact_relations = {
	#Scenario 0 Relations
	"general1" : {
		"and" : { "clues" : ["archie3", "B1", "A1", "archie4"],
		"result" : ["general2", "general2", "general4", "general3"] },
		"points" : 100
	},
	"general2" : {
		"supports" : { "clues" : ["suspectB"] },
		"points" : 20
	},
	"general3" : {
		"supports" : { "clues" : ["suspectArchie"] },
		"points" : 20
	},
	"general4" : {
		"supports" : { "clues" : ["suspectA"] },
		"points" : 20
	},
	"general5" : {
		"and" : { "clues" : ["office2"],
		"result" : ["general6"] },
		"points" : -1
	},
	"general6" : {
		"supports" : { "clues" : ["suspectB"] },
		"points" : -1
	},

	"archie1" : { 
		"and" : { "clues" : ["archie2"],
		"result" : ["general1"]},
		"supports" : { "clues" : ["eyy1"] },
		"points" : 10
	},
	"archie2" : { 
		"and" : { "clues" : ["archie1"],
		"result" : ["general1"] },
		"points" : 10
	},
	"archie3" : { 
		"and" : { "clues": ["general1"],
		"result" : ["general2"] },
		"supports" : { "clues": ["suspectB", "B1"], },
		"points" : 10
	},
	"archie4" : {
		"and" : { "clues" : ["general1"],
		"result" : ["general3"] },
		"contradicts" : { "clues" : ["suspectArchie"] },
		"points" : 10
	},

	"A1" : {
		"and" : { "clues" : ["general1"],
		"result" : ["general4"] },
		"supports" : { "clues" : ["suspectA"] },
		"points" : 10
	},
	"A2" : {
		"contradicts" : { "clues" : ["suspectA"] },
		"points" : 10
	},
	"A3" : {
		"supports" : { "clues" : ["suspectB"] },
		"points" : 10
	},

	"B1" : {
		"and" : { "clues" : ["general1"],
		"result" : ["general2"]},
		"supports" : { "clues" : ["suspectB", "archie3"] },
		"points" : 100
	},
	"B2" : { 
		"supports" : { "clues" : ["suspectA"] },
		"contradicts" : { "clues" : ["suspectB"] },
		"points" : 20
	},

	"library1" : {
		"and" : { "clues" : ["office1"],
		"result" : ["general5"] },
		"points" : 100
	},
	"kitchen1" : {
		"supports" : { "clues" : ["suspectB"]},
		"points" : 5
	},
	"office1" : {
		"and" : { "clues" : ["library1"],
		"result" : ["general5"] },
		"supports" : { "clues" : ["suspectA"]},
		"points" : 40
	},
	"office2" : {
		"and" : { "clues" : ["general5"],
		"result" : ["general6"] },
		"points" : 10
	},
}
