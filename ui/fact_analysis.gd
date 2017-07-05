extends "res://globals/interactive.gd"

export(String,FILE) var events_path = ""

var event_table = {}

var game
var menu
var inventory
var analysis_data

var first_clue

var row = 0
var col = 0

var max_col = 2

func back_to_game():
	menu.load_pressed()
	
func find_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	for item in inventory.clues:
		if id in item.values():
			return item

func set_curr_row_col():
	if col == max_col:
		row += 1
		col = 0
	else:
		col += 1

var col_width = 300
var col_offset = 100
var row_width = 250
var row_offset = 50

func instance_clue(clue_id, parents, children):
	var node = get_node("Clue").duplicate()
	node.set_pos(Vector2(col_width * col + col_offset, row_width * row + row_offset))
	node.id = clue_id
	node.content = find_clue(clue_id).title
	node.col = col
	node.row = row
	node.get_node("Label").set_text(node.content)
	
	if clue_id.substr(0,2) == "c/":
		clue_id.erase(0, 2)
	
	node.set_name(clue_id)
	node.connect("pressed", self, "clue_pressed", [clue_id])
	
	get_node("c").add_child(node)
	set_curr_row_col()

func instance_clues():
	for clue in game.clues:
		instance_clue(clue, null, null)

func instance_relation(clue_id, parents, children):
	print("Relation: " + str(clue_id) + str(parents) + str(children))
	
	if !analysis_data.created_relations.has(clue_id):
		analysis_data.created_relations[clue_id] = { "parents": [], "children": [] }
	
	if children != null:
		analysis_data.created_relations[clue_id]["children"].push_back(children)
		draw_relation(clue_id, children)
	elif (parents != null):
		for parent in parents:
			analysis_data.created_relations[clue_id]["parents"].push_back(parent)
			draw_relation(parent, clue_id)
		
	print(analysis_data.created_relations)

func get_selected_relation():
	if vm.get_global("therefore_selected"):
		return "and"
	if vm.get_global("supports_selected"):
		return "supports"
	if vm.get_global("contradicts_selected"):
		return "contradicts"

func process_clues(first_clue, second_clue):
	if analysis_data.fact_relations.has(first_clue):
		var relation = get_selected_relation()
		var fact_object = analysis_data.fact_relations[first_clue]
		
		if fact_object.has(relation) and fact_object[relation]["clues"].has(second_clue):
			if relation == "contradicts":
				print ("Clue contradicts other clue")
				print ("Contradict points: " + str(fact_object[relation]["points"]))
				instance_relation(first_clue, null, second_clue)
				
			if relation == "supports":
				print("Clue supports other clue: ")
				print ("Support points: " + str(fact_object[relation]["points"]))
				instance_relation(first_clue, null, second_clue)
				
			if relation == "and":
				var new_clue = fact_object[relation]["result"]
				if !vm.get_global("c/" + new_clue):
					instance_clue(new_clue, [first_clue, second_clue], null)
					instance_relation(new_clue, [first_clue, second_clue], null)
					game.clues.append("c/" + new_clue)
					vm.set_global("c/" + new_clue, true)
				else:
					print("Clue already found")
		else:
			print(analysis_data.default)
	else:
		print(analysis_data.default)
	
	print(first_clue)
	print(second_clue)
	print(vm.get_global("analysis_selected"))
	print(vm.get_global("therefore_selected"))
	print(vm.get_global("supports_selected"))
	print(vm.get_global("contradicts_selected"))

func draw_relation(parent, child):
	var arrow = get_node("arrow").duplicate()
	var parent_node = get_node("c/" + parent)
	var child_node = get_node("c/" + child)
	var clue_size = Vector2(child_node.get_rect().size.x, child_node.get_rect().size.y)
	var child_center = child_node.get_pos() + (clue_size / 2)
	var parent_center = parent_node.get_pos() + (clue_size / 2)
	
	#Set position relative to the parent clue box
	get_node("c/" + parent).add_child(arrow)
	arrow.set_pos(clue_size / 2)
	
	#Set scale to be long enough to reach the child box
	var distance = parent_center.distance_to(child_center)
	if(parent_center.y != child_center.y):
		distance += clue_size.y * (abs(child_node.row - parent_node.row ) + abs(child_node.col - parent_node.col) - 1)
	if(parent_center.x == child_center.x):
		distance += clue_size.y/2  - parent_node.row * clue_size.y/4#- clue_size.y/4 * 2 * (abs(child_node.row - parent_node.row) - 1)# (clue_size.y / 2) * (abs(child_node.row - parent_node.row)/2)

	#TODO multiply row_offset by 2 (aka the ROW the child node is in)
	var arrow_new_size = Vector2(distance + row_offset * child_node.row, arrow.get_rect().size.y)
	arrow.set_size(arrow_new_size)
	
	#Set the rotation to point to the child box
	var angle = parent_center.angle_to_point(child_center)
	var angle_offset = 1.571 #radians
	arrow.set_rotation(angle + angle_offset)

func clue_pressed(clue_id):
	var node = get_node("c/" + clue_id)
	get_node("cursor").set_pos(Vector2(120 + node.get_pos().x, 50 + node.get_pos().y))
	if vm.get_global("analysis_selected") == false:
		get_node("cursor").show()
	
	if vm.get_global("analysis_selected") == true:
		process_clues(first_clue, clue_id)
		first_clue = ""
		vm.set_global("analysis_selected", false)
		vm.set_global("therefore_selected", false)
		vm.set_global("supports_selected", false)
		vm.set_global("contradicts_selected", false)
		return

	if "use" in event_table:
		vm.run_event(event_table.use, {})
		first_clue = clue_id

func background_pressed():
	if(vm.can_interact()):
		get_node("cursor").hide()

func _ready():
	game = get_node("/root/game")
	inventory = preload("res://game/inventory.gd")
	menu = get_node("/root/game/hud_layer/inventory/Menu/Options/menu")

	analysis_data = get_node("AnalysisData")
	
	get_node("Back").connect("pressed", self, "back_to_game")
	get_node("Background/BackgroundButton").connect("pressed", self, "background_pressed")
	
	if events_path != "":
		event_table = vm.compile(events_path)
	
	instance_clues()