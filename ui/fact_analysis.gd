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
var nodes = []
var clue_size
var item_clue_size
var clue_distance
var item_clue_distance

const suspect_ids = [ "general3", "general4", "general5" ]

var first_clue

var row = 0
var col = 0

var max_col = 2

func back_to_game():
	if game.has_node("hud_layer/dialog"):
		game.get_node("hud_layer/dialog").stop()
	vm.game.analysis_camera_pos = get_node("center").get_pos()
	vm.game.analysis_camera_zoom = get_node("center/camera").get_zoom()
	vm.game.relations = analysis_data.created_relations
	vm.game.facts = analysis_data.fact_relations
	for clue in vm.game.clues:
		var clue_pos = get_node("c/" + clue).get_pos()
		vm.game.clue_positions[clue] = clue_pos
	menu.load_pressed("tempsave")

func find_item_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	for item in inventory.items:
		if id in item.values():
			return item

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

func instance_clue(clue_id, parents, children, is_item):
	var node
	var curr_clue_size
	if is_item:
		node = get_node("ItemClue").duplicate()
		curr_clue_size = item_clue_size
		var item = find_item_clue(clue_id)
		
		var spr = Sprite.new()
		spr.set_texture(load(item.icon))
		spr.set_pos(node.get_node("ClueButton/spritePosition").get_pos())
		spr.set_scale(spr.get_scale() * 2)
		
		node.get_node("ClueButton").add_child(spr)
		
	else:
		node = get_node("Clue").duplicate()
		node.show()
		if (clue_id in suspect_ids):
			node.get_node("ClueButton").set_normal_texture(load("res://ui/graphics/SuspectClue.png"))
			if(!vm.get_global("first_suspect")):
				vm.set_global("first_suspect", true)
				game.get_node("speech_dialogue_player").start(["", analysis_data.first_suspect], vm.level.current_context, false)
			else:
				game.get_node("speech_dialogue_player").start(["", analysis_data.suspect], vm.level.current_context, false)
		curr_clue_size = clue_size
	
	node.set_z(0)
	var proposed_position = Vector2(col_width * col + col_offset, row_width * row + row_offset)
	if parents != null:
		var dist = abs(get_node("c/" + parents[0]).get_pos().x - get_node("c/" + parents[1]).get_pos().x)
		var xpos = get_node("c/" + parents[0]).get_pos().x + (dist / 2)
		var ypos = get_node("c/" + parents[0]).get_pos().y + curr_clue_size.y * 1.5
		proposed_position = Vector2(xpos, ypos)
	
	node.set_pos(proposed_position)
	node.id = clue_id
	node.content = find_clue(clue_id).title
	node.col = col
	node.row = row
	node.get_node("ClueButton").get_node("Label").set_text(node.content)
	if (analysis_data.fact_relations.has(clue_id)):
		node.get_node("ClueButton").get_node("points").set_text(str(analysis_data.fact_relations[clue_id]["points"]))
	
	if clue_id.substr(0,2) == "c/":
		clue_id.erase(0, 2)
	
	node.set_name(clue_id)
	node.get_node("ClueButton").connect("button_down", self, "clue_pressed", [clue_id])
	node.get_node("ClueButton").connect("button_up", self, "clue_released", [clue_id])
	
	get_node("c").add_child(node)
	set_curr_row_col()

func is_item_clue(clue_id):
	for item in inventory.items:
		if clue_id == item.id:
			return true
	return false

func instance_clues():
	for clue in game.clues:
		if is_item_clue(clue):
			instance_clue(clue, null, null, true)
		else:
			instance_clue(clue, null, null, false)
			
		if vm.game.clue_positions.has(clue):
			get_node("c/" + clue).set_pos(vm.game.clue_positions[clue])

func instance_relations():
	for clueid in analysis_data.created_relations.keys():
		for child in game.relations[clueid]["children"]:
			draw_relation(clueid, child[0], child[1])

func validate_relation(parent, child):
	if (parent == null or child == null):
		return false
	var nodes = [parent]
	var queue = [parent]
	while queue.size() > 0:
		var curr = queue.back()
		queue.pop_back()
		if analysis_data.created_relations.has(curr):
			#check if child already has path to parent (score already propagated)
			for c in analysis_data.created_relations[curr]["children"]:
				if child == c[0]:
					return false
				elif !nodes.has(c[0]):
					nodes.push_back(c[0])
					queue.push_back(c[0])
			#check if child is already a parent of parent (avoid cycles)
			for p in analysis_data.created_relations[curr]["parents"]:
				if child == p[0]:
					return false
				elif !nodes.has(p[0]):
					nodes.push_back(p[0])
					queue.push_back(p[0])
		
	return true

func instance_relation(clue_id, parents, children, relation):
	print("Relation: " + str(clue_id) + str(parents) + str(children))
	
	if !analysis_data.created_relations.has(clue_id):
		analysis_data.created_relations[clue_id] = { "parents": [], "children": [] }

	if children != null:
		for child in children:
			analysis_data.created_relations[clue_id]["children"].push_back([child, relation])
			if !analysis_data.created_relations.has(child):
				analysis_data.created_relations[child] = { "parents": [], "children": [] }
			analysis_data.created_relations[child]["parents"].push_back([clue_id, relation])
			draw_relation(clue_id, child, relation)

	if (parents != null):
		for parent in parents:
			analysis_data.created_relations[clue_id]["parents"].push_back([parent, relation])
			if !analysis_data.created_relations.has(parent):
				analysis_data.created_relations[parent] = { "parents": [], "children": [] }
			analysis_data.created_relations[parent]["children"].push_back([clue_id, relation])
			draw_relation(parent, clue_id, relation)

func get_selected_relation():
	if vm.get_global("therefore_selected"):
		return "and"
	if vm.get_global("supports_selected"):
		return "supports"
	if vm.get_global("contradicts_selected"):
		return "contradicts"

func update_points(parent, child, relation):
	if relation == "contradicts" or relation == "supports":
		var parent_points = analysis_data.fact_relations[parent[0]]["points"]
		var child_points = analysis_data.fact_relations[child]["points"]
		if relation == "contradicts":
			parent_points = -1 * .1 * parent_points
			child_points = -1 * .1 * child_points
		else:
			parent_points = .1 * parent_points
			child_points = .1 * child_points
		var new_child_points = analysis_data.fact_relations[child]["points"]
		new_child_points += parent_points
		analysis_data.fact_relations[child]["points"] = new_child_points
		get_node("c/" + child).get_node("ClueButton/points").set_text(str(new_child_points))
		if relation == "supports":
			var new_parent_points = analysis_data.fact_relations[parent[0]]["points"]
			new_parent_points += child_points
			analysis_data.fact_relations[parent[0]]["points"] = new_parent_points
			get_node("c/" + parent[0]).get_node("ClueButton/points").set_text(str(new_parent_points))
	if relation == "and":
		var parent_points = analysis_data.fact_relations[parent[0]]["points"]
		var parent_points_two = analysis_data.fact_relations[parent[1]]["points"]
		var parent_average = (parent_points + parent_points_two) * .5
		var child_points = parent_average
		analysis_data.fact_relations[child]["points"] = child_points
		get_node("c/" + child).get_node("ClueButton/points").set_text(str(child_points))
	if(int(get_node("c/" + child).get_node("ClueButton/points").get_text()) >= analysis_data.SUSPECT_THRESHOLD):
		vm.set_global(str("isSuspect" + child), true)

func update_children_points(node):
	var nodes = [node]
	if !analysis_data.created_relations.has(node):
		return
	
	var queue = [node]
	while queue.size() > 0:
		var curr = queue.back()
		queue.pop_back()
		if analysis_data.created_relations.has(curr):
			for child in analysis_data.created_relations[curr]["children"]:
				var child_id = child[0]
				var relation = child[1]
				
				if relation == "and":
					var potential_parents = analysis_data.created_relations[child_id]["parents"]
					var other_parent = null
					for p in potential_parents:
						p = p[0] #the id, not the relation
						if p != curr and analysis_data.fact_relations[p].has("and"):
							if analysis_data.fact_relations[p]["and"]["result"].has(child_id):
								other_parent = p
					if other_parent == null:
						print("ERROR: cannot find relation with other parent.")
						continue
					update_points([curr, other_parent], child_id, relation)
				elif relation == "contradicts" or relation == "supports":
					var a = 0 # do nothing
					#update_points([curr], child_id, relation)
				
				if !nodes.has(child[0]):
					nodes.push_back(child[0])
					queue.push_back(child[0])

func process_clues(first_clue, second_clue):
	if analysis_data.fact_relations.has(first_clue):
		var relation = get_selected_relation()
		var fact_object = analysis_data.fact_relations[first_clue]
		var result_object = null
		if relation == "and" and fact_object.has(relation):
			result_object = fact_object[relation]["result"][fact_object[relation]["clues"].find(second_clue)]
		
		if (!fact_object.has(relation) or (relation == "and" and result_object == null)):
			game.get_node("speech_dialogue_player").start(["", analysis_data.default], vm.level.current_context, false)
			return
		
		if (relation == "and" 
		and (!validate_relation(first_clue, result_object) 
		or !validate_relation(second_clue, result_object))):
			print("Error: Child relation already exists or relation would create cycle")
			#game.get_node("speech_dialogue_player").start(["", analysis_data.default], vm.level.current_context, false)
			#return
	
		if fact_object.has(relation) and fact_object[relation]["clues"].has(second_clue):
			if relation == "contradicts":
				instance_relation(first_clue, null, [second_clue], relation)
				update_points([first_clue], second_clue, "contradicts")
				update_children_points(second_clue)
				
			if relation == "supports":
				print("Clue supports other clue: ")
				#print ("Support points: " + str(fact_object[relation]["points"]))
				instance_relation(first_clue, null, [second_clue], relation)
				update_points([first_clue], second_clue, "supports")
				update_children_points(second_clue)
				
			if relation == "and":
				var index = fact_object[relation]["clues"].find(second_clue)
				var new_clue = fact_object[relation]["result"][index]
				if !vm.get_global("c/" + new_clue):
					instance_clue(new_clue, [first_clue, second_clue], null, false)
					instance_relation(new_clue, [first_clue, second_clue], null, "and")
					update_points([first_clue, second_clue], new_clue, relation)
					update_children_points(new_clue)
					game.clues.append(new_clue)
					vm.set_global("c/" + new_clue, true)
				else:
					game.get_node("speech_dialogue_player").start(["", "Clue already found!"], vm.level.current_context, false)
					return
		else:
			game.get_node("speech_dialogue_player").start(["", analysis_data.default], vm.level.current_context, false)
			return
	else:
		game.get_node("speech_dialogue_player").start(["", analysis_data.default], vm.level.current_context, false)
		return

func get_clue_size(node):
	var curr_size
	if (node.get_filename() == "res://ui/InventoryClue.tscn"):
		curr_size = item_clue_size
	else:
		curr_size = clue_size
		
	return curr_size

func draw_relation(parent, child, relation):
	
	var arrow = get_node("arrow").duplicate()
	var parent_node = get_node("c/" + parent)
	var child_node = get_node("c/" + child)
	var child_size = get_clue_size(child_node)
	var parent_size = get_clue_size(parent_node)
	var child_center = child_node.get_pos() + (clue_size / 2)
	var parent_center = parent_node.get_pos() + (clue_size / 2)
	arrow.set_normal_texture(load("res://ui/graphics/relationLine" + relation + ".png"))
	
	#Set position relative to the parent clue box
	get_node("c/" + parent + "/ClueButton").add_child(arrow)
	arrow.set_pos(clue_size / 2)
	
	arrow.set_name("arrow" + child)
	
	update_draw_relation(parent_center, child_center, parent, child)

func update_draw_relation(parent_center, child_center, parent_id, child_id):
	var arrow = get_node("c/" + parent_id + "/ClueButton/arrow" + child_id)
	
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
	
	if (Input.is_action_pressed("change_color")):
		print("Color changing")
	
	if (Input.is_action_pressed("right_click")):
		nodes = find_all_clicked_nodes(curr_node.id)
	
	if (Input.is_action_pressed("combine") and Input.is_mouse_button_pressed(BUTTON_LEFT)):
		
		if vm.get_global("analysis_selected") == true:
			process_clues(first_clue, clue_id)
			vm.set_global("analysis_selected", false)
			vm.set_global("therefore_selected", false)
			vm.set_global("supports_selected", false)
			vm.set_global("contradicts_selected", false)
			return
			
		first_clue = ""
	
		if "use" in event_table:
			vm.run_event(event_table.use, {})
			first_clue = clue_id

func clue_released(clue_id):
	dragging = false
	curr_node.set_z(0)
	curr_node = null
	nodes = []

func background_pressed():
	if(vm.can_interact()):
		get_node("cursor").hide()

#Modified BFS to search all connected nodes
func find_all_clicked_nodes(node):
	if node == null: 
		return null
	
	var nodes = [node]
	if !analysis_data.created_relations.has(node):
		return nodes
	
	var queue = [node]
	while queue.size() > 0:
		var curr = queue.back()
		queue.pop_back()
		if analysis_data.created_relations.has(curr):
			for child in analysis_data.created_relations[curr]["children"]:
				if !nodes.has(child[0]):
					nodes.push_back(child[0])
					queue.push_back(child[0])
			for parent in analysis_data.created_relations[curr]["parents"]:
				if !nodes.has(parent[0]):
					nodes.push_back(parent[0])
					queue.push_back(parent[0])
			
	return nodes

func drag_box():
	var pos = get_global_mouse_pos()
	curr_node.set_z(1)
	
	var clue_size = get_clue_size(curr_node)
	
	if Input.is_action_pressed("right_click"):
		
		var curr_node_pos = curr_node.get_pos()
		curr_node.set_global_pos(pos)
		curr_node.set_pos(curr_node.get_pos() - clue_size / 4)
		var curr_node_pos_diff = curr_node_pos - curr_node.get_pos()
		
		#update ALL positions
		for nodeid in nodes:
			if nodeid != curr_node.id:
				var node = get_node("c/" + nodeid)
				var node_pos = node.get_pos()
				
				var new_pos = -curr_node_pos_diff + node_pos
				node.set_pos(new_pos)
	
	elif Input.is_mouse_button_pressed(BUTTON_LEFT):
		
		curr_node.set_global_pos(pos)
		curr_node.set_pos(curr_node.get_pos() - clue_size / 4)
		
		if (analysis_data.created_relations.has(curr_node.id)):
			var children = analysis_data.created_relations[curr_node.id]["children"]
			var parent_center = curr_node.get_pos() + (clue_size / 2)
			for child in children:
				var child_node = get_node("c/" + child[0])
				var child_center = child_node.get_pos() + (clue_size / 2)
				update_draw_relation(parent_center, child_center, curr_node.id, child[0])
	
			var parents = analysis_data.created_relations[curr_node.id]["parents"]
			var child_center = curr_node.get_pos() + (clue_size / 2)
			for parent in parents:
				var parent_node = get_node("c/" + parent[0])
				var parent_center = parent_node.get_pos() + (clue_size / 2)
				update_draw_relation(parent_center, child_center, parent[0], curr_node.id)

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

func _ready():
	game = get_node("/root/game")
	inventory = preload("res://game/data/inventory.gd")
	menu = get_node("/root/game/hud_layer/inventory/Menu/Options/menu")
	clue_size = Vector2(get_node("Clue/ClueButton").get_rect().size.x, get_node("Clue/ClueButton").get_rect().size.y)
	item_clue_size =  Vector2(get_node("ItemClue/ClueButton").get_rect().size.x, get_node("ItemClue/ClueButton").get_rect().size.y)
	
	clue_distance = sqrt(clue_size.x * clue_size.x + clue_size.y * clue_size.y)
	item_clue_distance = sqrt(item_clue_size.x * item_clue_size.x + item_clue_size.y * item_clue_size.y)
	analysis_data = get_node("AnalysisData")
	camera = get_node("center/camera")
	
	get_node("canvas/Back").connect("pressed", self, "back_to_game")
	get_node("Background/BackgroundButton").connect("pressed", self, "background_pressed")
	
	set_fixed_process(true)

	if events_path != "":
		event_table = vm.compile(events_path)
	
	get_node("center").set_pos(vm.game.analysis_camera_pos)
	get_node("center/camera").set_zoom(vm.game.analysis_camera_zoom)
	if vm.game.relations.keys().size() > 0:
		analysis_data.created_relations = vm.game.relations
	if vm.game.facts.keys().size() > 0:
		analysis_data.fact_relations = vm.game.facts
	
	instance_clues()
	instance_relations()