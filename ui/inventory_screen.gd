var vm
var game

var item

var hand

var clue_size
var item_clue_size
var clue_parent
var curr_clue
var analysis_data
var curr_node_original_pos

var inventory

var cur_item = -1
var first_item = 0

var item_slots
var slot_names

var item_cursor

var item_cols = 3
var item_rows = 4

var equipped_current

var events

var dragging = false

signal inventory_closed

var base_path = "res://scenes/test/"

#OPEN AND CLOSE MENU WINDOWS
#OPTIONS, MAP, INVENTORY
func close():
	hide()
	game.remove_hud(self)
	emit_signal("inventory_closed")

func open():
	instance_clues()
	show()
	game.add_hud(self)

func open_fact_analysis():
	if game.current_scene.get_name() != "Analysis":
		get_node("Menu/Options/menu").save_pressed("tempsave")
		game.change_scene(["res://ui/FactAnalysis.tscn"], vm.level.current_context)
		close()

#INPUT EVENTS
func input(event):
	if event.is_echo():
		return
	if !event.is_pressed():
		return

	var dir = Vector2()
	if event.is_action("ui_up"):
		dir.y = -1
	elif event.is_action("ui_down"):
		dir.y = 1
	elif event.is_action("ui_left"):
		dir.x = -1
	elif event.is_action("ui_right"):
		dir.x = 1

	if dir != Vector2():
		move_cursor(dir)
		update_pages()

	if event.is_action("inventory_toggle"):
		close()

#CLUES
func clue_pressed(clue_id):
	var node = clue_parent.get_node(clue_id)
	curr_node_original_pos = node.get_global_pos()
	var clue_name = node.get_name()
	var parent = node.get_parent()
	
	#real clue stays put, copy is dragged
	var copy = node.duplicate()
	reparent(copy, null, null)
	copy.set_global_pos(curr_node_original_pos)
	curr_clue = copy
	dragging = true

func reparent(child, current_parent, target_parent):
	if current_parent != null:
		current_parent.remove_child(child)
	if target_parent == null:
		add_child(child)
	else:
		target_parent.add_child(child)

func clue_released(clue_id):
	var areas = get_node(clue_id).get_node("ClueButton/Area2D").get_overlapping_areas()
	for area in areas:
		if area.get_name() == "SuspectArea":
			var suspect = area.get_node("../../").get_name()
			check_suspect(suspect, clue_id)
	
	dragging = false
	remove_child(curr_clue)
	curr_clue = null

func check_suspect(suspect_id, clue_id):
	var fact = analysis_data.fact_relations[clue_id]
	var suspect = "suspect" + suspect_id
	if fact.has("supports") and suspect in fact["supports"]["clues"]:
		if relation_exists(clue_id, suspect_id, "supports"):
			print("Clue already found")
			return
		var points = fact["points"]
		var suspect_parent = get_node("Menu/Suspects/SuspectControl/ScrollContainer/HBoxContainer")
		var bar = suspect_parent.get_node(suspect_id).get_node("Sprite/ProgressBar")
		if (bar.get_progress_texture().get_name() == "progress_negative.PNG"):
			if (bar.get_value()*-1 + points) >= 0:
				bar.set_progress_texture(load("res://ui/graphics/progress_progress.PNG"))
				bar.set_value(bar.get_value()*-1 + points)
			else:
				bar.set_value(bar.get_value() - points)
		elif (bar.get_value() + points) >= 0:
			bar.set_progress_texture(load("res://ui/graphics/progress_progress.PNG"))
			bar.set_value(bar.get_value() + points)
		bar.get_node("Label").set_text(str(bar.get_value()))
		instance_relation(clue_id, suspect_id, "supports")
	elif fact.has("contradicts") and suspect in fact["contradicts"]["clues"]:
		if relation_exists(clue_id, suspect_id, "contradicts"):
			print("Clue already found")
			return
		var points = fact["points"]
		var suspect_parent = get_node("Menu/Suspects/SuspectControl/ScrollContainer/HBoxContainer")
		var bar = suspect_parent.get_node(suspect_id).get_node("Sprite/ProgressBar")
		if (bar.get_progress_texture().get_name() == "progress_negative.PNG"):
			bar.set_value(bar.get_value() + points)
		elif (bar.get_value() - points) < 0:
			bar.set_progress_texture(load("res://ui/graphics/progress_negative.PNG"))
			bar.set_value(-1*(bar.get_value() - points))
		else:
			bar.set_value(bar.get_value() - points)
		bar.get_node("Label").set_text(str(bar.get_value()))
		instance_relation(clue_id, suspect_id, "contradicts")
	else:
		print("Hmm, nothing.")

func instance_relation(clue_id, suspect_id, relation):
	if !analysis_data.created_relations.has(clue_id):
		analysis_data.created_relations[clue_id] = { "parents": [], "children": [] }
	if !analysis_data.created_relations.has(suspect_id):
		analysis_data.created_relations[suspect_id] = { "parents": [], "children": [] }

	analysis_data.created_relations[suspect_id]["parents"].push_back([clue_id, relation])
	analysis_data.created_relations[clue_id]["children"].push_back([suspect_id, relation])

func relation_exists(clue_id, suspect_id, relation):
	if !analysis_data.created_relations.has(clue_id):
		return false
	if !analysis_data.created_relations.has(suspect_id):
		return false
	for item in analysis_data.created_relations[clue_id]["children"]:
		if item[0] == suspect_id and item[1] == relation:
			return true
	return false

func is_item_clue(clue_id):
	for item in inventory.items:
		if clue_id == item.id:
			return true
	return false

func find_item_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	for item in inventory.items:
		if id == item.id:
			return item

func find_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	for item in inventory.clues:
		if id == item.id:
			return item

func instance_clues():
	for clue in game.clues:
		if !clue_parent.has_node(clue):
			if is_item_clue(clue):
				instance_clue(clue, null, null, true)
			else:
				instance_clue(clue, null, null, false)
			
func instance_clue(clue_id, parents, children, is_item):
	var node
	if is_item:
		node = get_node("ItemClue").duplicate()
		var item = find_item_clue(clue_id)
		var spr = Sprite.new()
		spr.set_texture(load(item.icon))
		spr.set_pos(node.get_node("ClueButton/spritePosition").get_pos())
		spr.set_scale(spr.get_scale() * 2)
		node.get_node("ClueButton").add_child(spr)
	else:
		node = get_node("Clue").duplicate()
	node.id = clue_id
	node.content = find_clue(clue_id).title
	node.get_node("ClueButton").get_node("Label").set_text(node.content)
	if (analysis_data.fact_relations.has(clue_id)):
		node.get_node("ClueButton").get_node("points").set_text(str(analysis_data.fact_relations[clue_id]["points"]))
	
	if clue_id.substr(0,2) == "c/":
		clue_id.erase(0, 2)
	node.set_name(clue_id)
	
	node.get_node("ClueButton").connect("button_down", self, "clue_pressed", [clue_id])
	node.get_node("ClueButton").connect("button_up", self, "clue_released", [clue_id])
	
	get_node("Menu/Suspects/SuspectControl/ScrollContainerClues/VBoxContainer").add_child(node)

func drag_box():
	var pos = get_global_mouse_pos()
	var clue_size = get_clue_size(curr_clue)
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		curr_clue.set_global_pos(pos)
		curr_clue.set_pos(curr_clue.get_pos() - clue_size / 4)

func get_clue_size(node):
	var curr_size
	if (node.get_filename() == "res://ui/InventoryClue.tscn"):
		curr_size = item_clue_size
	else:
		curr_size = clue_size
		
	return curr_size

func _fixed_process(delta):
	if (dragging and Input.is_mouse_button_pressed(BUTTON_LEFT)):
			drag_box()

func _ready():
	game = get_node("/root/game")
	vm = get_node("/root/vm")
	set_fixed_process(true)
	
	clue_size = Vector2(get_node("Clue/ClueButton").get_rect().size.x, get_node("Clue/ClueButton").get_rect().size.y)
	item_clue_size =  Vector2(get_node("ItemClue/ClueButton").get_rect().size.x, get_node("ItemClue/ClueButton").get_rect().size.y)
	
	clue_parent = get_node("Menu/Suspects/SuspectControl/ScrollContainerClues/VBoxContainer")
	analysis_data = get_node("AnalysisData")
	instance_clues()

	inventory = preload("res://game/data/inventory.gd")