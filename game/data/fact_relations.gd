func _ready():
	return

var created_relations = {
}

const SUSPECT_THRESHOLD = 90 #switch to 100
const default = "This doesn't make sense to me..."
const suspect = "Looks like we found a new suspect we can accuse..."

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
		"points" : 100
	},
	"archie3" : { 
		"and" : { "clues": ["general1"],
		"result" : ["general2"] },
		"supports" : { "clues": ["suspectB"] },
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
		"supports" : { "clues" : ["suspectB"] },
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
