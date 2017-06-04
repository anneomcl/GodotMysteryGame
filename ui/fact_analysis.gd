extends "res://globals/interactive.gd"

export(String,FILE) var events_path = ""

var event_table = {}

var game
var menu
var inventory

var row = 0
var col = 0

var max_row = 4

func back_to_game():
	menu.load_pressed()
	
func find_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	else:
		return
	for item in inventory.clues:
		if id in item.values():
			return item

func set_curr_row_col():
	if row == max_row:
		row = 0
		col += 1
	else:
		row += 1

func instance_clue():
	for clue in game.clues:
		var node = get_node("Clue").duplicate()
		set_curr_row_col()
		node.set_pos(Vector2(400 * row - 300, 250 * col + 50))
		node.id = clue
		node.content = find_clue(clue).title
		node.get_node("Label").set_text(node.content)
		
		clue.erase(0, 2)
		node.set_name(clue)
		node.connect("pressed", self, "clue_pressed", [clue])
		
		get_node("c").add_child(node)

func clue_pressed(clue_id):
	var node = get_node("c/" + clue_id)
	get_node("cursor").set_pos(Vector2(120 + node.get_pos().x, 50 + node.get_pos().y))
	get_node("cursor").show()
	
	if "use" in event_table:
		vm.run_event(event_table.use, {})

func background_pressed():
	if(vm.can_interact()):
		get_node("cursor").hide()

func _ready():
	game = get_node("/root/game")
	inventory = preload("res://game/inventory.gd")
	menu = get_node("/root/game/hud_layer/inventory/Menu/Options/menu")

	get_node("Back").connect("pressed", self, "back_to_game")
	get_node("Background/BackgroundButton").connect("pressed", self, "background_pressed")
	
	
	if events_path != "":
		event_table = vm.compile(events_path)
	
	instance_clue()