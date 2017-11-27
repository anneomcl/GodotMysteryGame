func _ready():
	return

var created_relations = {
}

var clues_used_on_suspects = []

const SUSPECT_THRESHOLD = 90
const default = "This doesn't make sense to me..."
const look_further = "I may need to analyze this clue before applying it to a suspect."
const supports = "This clue supports their guilt."
const contradicts = "This clue supports their innocence."
const found = "I already matched that clue to this suspect."
const no_puzzle = "I need to find more clues to analyze."
const puzzle_solved_success = "A-ha! I think I've solved this one."

var puzzles = {
	"puzzle1" : {
		"clues" : ["archie1", "archie2"],
		"intermediate" : [],
		"solution" : 
			{ "therefore" : 1, "supports" : 0, "contradicts" : 0 },
		"is_solved" : false
	},
	"puzzle2" : {
		"clues" : ["general1", "archie3", "B1", "B3", "kitchen1"],
		"intermediate" : ["general2", "general3", "general4"],
		"solution" : 
			{ "therefore" : 1, "supports" :  2, "contradicts" : 1},
		"is_solved" : false
	},
	"puzzle3" : {
		"clues" : ["general1", "archie4", "archie5"],
		"intermediate" : [],
		"solution" : { "therefore" : 1, "supports" : 1, "contradicts" : 0 },
		"is_solved" : false
	},
	"puzzle4" : {
		"clues" : ["general1", "A1", "A2"],
		"intermediate" : [],
		"solution" : { "therefore" : 1, "supports" : 0, "contradicts" : 1 },
		"is_solved" : false
	},
	"puzzle5" : {
		"clues" : ["library1", "office1", "office2"],
		"intermediate" : [ "general5", "general6" ],
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
		"points" : 50
	},
	"general2" : {
		"supports" : { "clues" : ["suspectB"] },
		"contradicts" : { "clues" : ["B3"] },
		"points" : 20
	},
	"general3" : {
		"supports" : { "clues" : ["suspectarchie", "archie5"] },
		"points" : 5
	},
	"general4" : {
		"supports" : { "clues" : ["suspectA"] },
		"contradicts" : { "clues" : ["A2"] },
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
		"supports" : { "clues" : [] },
		"points" : 50
	},
	"archie2" : { 
		"and" : { "clues" : ["archie1"],
		"result" : ["general1"] },
		"points" : 50
	},
	"archie3" : { 
		"and" : { "clues": ["general1"],
		"result" : ["general2"] },
		"supports" : { "clues": ["B1"], },
		"points" : 20
	},
	"archie4" : {
		"and" : { "clues" : ["general1"],
		"result" : ["general3"] },
		"contradicts" : { "clues" : ["suspectarchie"] },
		"points" : 30
	},
	"archie5" : {
		"supports" :{ "clues" : ["general3"]},
		"points" : 5
	},

	"A1" : {
		"and" : { "clues" : ["general1"],
		"result" : ["general4"] },
		"supports" : { "clues" : [] },
		"points" : 20
	},
	"A2" : {
		"contradicts" : { "clues" : ["general4"] },
		"points" : 20 
	},
	"A3" : {
		"supports" : { "clues" : ["suspectB"] },
		"points" : 20
	},

	"B1" : {
		"and" : { "clues" : ["general1"],
		"result" : ["general2"]},
		"supports" : { "clues" : ["archie3", "kitchen1"] },
		"points" : 20
	},
	"B2" : { 
		"supports" : { "clues" : ["suspectA"] },
		"points" : 20
	},
	"B3" : {
		"contradicts" : { "clues" : ["general2"] },
		"points" : 20
	},

	"library1" : {
		"and" : { "clues" : ["office1"],
		"result" : ["general5"] },
		"points" : 100
	},
	"kitchen1" : {
		"supports" : { "clues" : ["B1"]},
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
		"points" : 40
	},
}
