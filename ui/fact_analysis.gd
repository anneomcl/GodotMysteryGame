extends "res://globals/interactive.gd"

export(String,FILE) var events_path = ""

var event_table = {}

var zoom_step = 2
var scroll_speed = 20 
var camera
var move_direction = Vector2(0, 0)

var game
var menu
var inventory
var analysis_data

var dragging = false
var curr_node #node currently selected
var clue_size
var clue_distance

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
	
	#get distance from proposed position to parent 1
	#if distance is not at least clue_size away, add the offset
	
	var proposed_position = Vector2(col_width * col + col_offset, row_width * row + row_offset)
	if parents != null:
		for parent in parents:
			var parentNode = get_node("c/" + parent)
			if (proposed_position.distance_to(parentNode.get_pos()) < clue_distance/4):
				proposed_position.x += clue_size.x/2
	
	node.set_pos(proposed_position)
	node.id = clue_id
	node.content = find_clue(clue_id).title
	node.col = col
	node.row = row
	node.get_node("Label").set_text(node.content)
	
	if clue_id.substr(0,2) == "c/":
		clue_id.erase(0, 2)
	
	node.set_name(clue_id)
	node.connect("button_down", self, "clue_pressed", [clue_id])
	node.connect("button_up", self, "clue_released", [clue_id])
	
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
		for child in children:
			analysis_data.created_relations[clue_id]["children"].push_back(child)
			if !analysis_data.created_relations.has(child):
				analysis_data.created_relations[child] = { "parents": [], "children": [] }
			analysis_data.created_relations[child]["parents"].push_back(clue_id)
			draw_relation(clue_id, child)

	if (parents != null):
		for parent in parents:
			analysis_data.created_relations[clue_id]["parents"].push_back(parent)
			if !analysis_data.created_relations.has(parent):
				analysis_data.created_relations[parent] = { "parents": [], "children": [] }
			analysis_data.created_relations[parent]["children"].push_back(clue_id)
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
				#print ("Contradict points: " + str(fact_object[relation]["points"]))
				instance_relation(first_clue, null, [second_clue])
				
			if relation == "supports":
				print("Clue supports other clue: ")
				#print ("Support points: " + str(fact_object[relation]["points"]))
				instance_relation(first_clue, null, [second_clue])
				
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
	
	update_draw_relation(parent_center, child_center, parent)

func update_draw_relation(parent_center, child_center, parent_id):
	var arrow = get_node("c/" + parent_id + "/arrow")
	
	#Set scale to be long enough to reach the child box
	var distance = parent_center.distance_to(child_center) * 2
	
	var arrow_new_size = Vector2(distance, arrow.get_rect().size.y)
	arrow.set_size(arrow_new_size)
	
	#Set the rotation to point to the child box
	var angle = parent_center.angle_to_point(child_center)
	var angle_offset = 1.571 #radians
	arrow.set_rotation(angle + angle_offset)

func clue_pressed(clue_id):
	var node = get_node("c/" + clue_id)
	dragging = true
	curr_node = node
	
	if (Input.is_action_pressed("combine")):
		#get_node("cursor").set_pos(Vector2(120 + node.get_pos().x, 50 + node.get_pos().y))
		#if vm.get_global("analysis_selected") == false:
			#TO-DO, fix cursor maybe get_node("cursor").show()
		
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

func clue_released(clue_id):
	dragging = false
	curr_node = null

func background_pressed():
	if(vm.can_interact()):
		get_node("cursor").hide()


#TODO do a proper BFS
func find_all_clicked_nodes(node):
	if node == null: 
		return null
	
	if !analysis_data.created_relations.has(node):
		return [node]
	
	var nodes = [node]
	for child in analysis_data.created_relations[node]["children"]:
		if !nodes.has(child):
			nodes.push_back(child)
	for parent in analysis_data.created_relations[node]["parents"]:
		if !nodes.has(parent):
			nodes.push_back(parent)
			
	return nodes

func drag_box():
	var pos = get_global_mouse_pos()
	
	if Input.is_action_pressed("right_click"):
		#find all nodes associated with the clicked node (recursively later)
		var nodes = find_all_clicked_nodes(curr_node.id)
		
		#update ALL positions
		for nodeid in nodes:
			var node = get_node("c/" + nodeid)
			
			#set the position relative to the current node
			#find the x/y difference between the node and current node
			#var global_pos = node.get_global_pos()
			#var offset_global_pos = global_pos - curr_node.get_global_pos()
			
			#node.set_global_pos(pos + offset_global_pos)
			#node.set_pos(node.get_pos() - clue_size / 4)
	
	elif Input.is_mouse_button_pressed(BUTTON_LEFT):
		
		#TO-DO: Translate the offset into global coords (screen coords)
		curr_node.set_global_pos(pos)
		curr_node.set_pos(curr_node.get_pos() - clue_size / 4)
		
		if (analysis_data.created_relations.has(curr_node.id)):
			var children = analysis_data.created_relations[curr_node.id]["children"]
			var parent_center = curr_node.get_pos() + (clue_size / 2)
			for child in children:
				var child_node = get_node("c/" + child)
				var child_center = child_node.get_pos() + (clue_size / 2)
				update_draw_relation(parent_center, child_center, curr_node.id)
	
			var parents = analysis_data.created_relations[curr_node.id]["parents"]
			var child_center = curr_node.get_pos() + (clue_size / 2)
			for parent in parents:
				var parent_node = get_node("c/" + parent)
				var parent_center = parent_node.get_pos() + (clue_size / 2)
				update_draw_relation(parent_center, child_center, parent)
		

func _fixed_process(delta):
	if (dragging and Input.is_mouse_button_pressed(BUTTON_LEFT)):
		drag_box()
	elif Input.is_action_pressed("zoom_in"):
		var new_zoom = Vector2(camera.get_zoom().x + zoom_step * delta, camera.get_zoom().y + zoom_step * delta)
		camera.set_zoom(Vector2(new_zoom.x, new_zoom.y))
	elif Input.is_action_pressed("zoom_out"):
		var new_zoom = Vector2(camera.get_zoom().x - zoom_step * delta, camera.get_zoom().y - zoom_step * delta)
		camera.set_zoom(Vector2(new_zoom.x, new_zoom.y))
	
	move_direction = Vector2(0,0)
	if(Input.is_action_pressed("ui_left")):
		move_direction += Vector2(-1, 0)
	if(Input.is_action_pressed("ui_right")):
		move_direction += Vector2(1, 0)
	if(Input.is_action_pressed("ui_up")):
		move_direction += Vector2(0, -1)
	if(Input.is_action_pressed("ui_down")):
		move_direction += Vector2(0, 1)
	if move_direction != Vector2(0, 0):
		get_node("center").move(move_direction * scroll_speed)

func _input(event):
	return

func _ready():
	game = get_node("/root/game")
	inventory = preload("res://game/inventory.gd")
	menu = get_node("/root/game/hud_layer/inventory/Menu/Options/menu")
	clue_size = Vector2(get_node("Clue").get_rect().size.x, get_node("Clue").get_rect().size.y)
	clue_distance = sqrt(clue_size.x * clue_size.x + clue_size.y * clue_size.y)
	analysis_data = get_node("AnalysisData")
	camera = get_node("center/camera")
	
	get_node("canvas/Back").connect("pressed", self, "back_to_game")
	get_node("Background/BackgroundButton").connect("pressed", self, "background_pressed")
	
	set_fixed_process(true)

	if events_path != "":
		event_table = vm.compile(events_path)
	
	instance_clues()