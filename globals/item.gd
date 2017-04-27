extends "res://globals/interactive.gd"

export(String,FILE) var events_path = ""

var event_table = {}

func interact(params):
	# example interaction

	if "use" in event_table:
		vm.run_event(event_table.use, {})

func _ready():

	if events_path != "":
		event_table = vm.compile(events_path)

