var vm
var game

var item

var dummy
var dummy_item

var hand

var clue_size
var item_clue_size
var clue_parent
var evidence_parent
var curr_clue
var analysis_data
var curr_node_original_pos
var clues_used_on_suspects = []

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

signal clues_instanced
signal inventory_closed
signal inventory_opened

var base_path = "res://scenes/test/"

#OPEN AND CLOSE MENU WINDOWS
#OPTIONS, MAP, INVENTORY
func close():
	hide()
	dummy.queue_free()
	dummy_item.queue_free()
	game.remove_hud(self)
	emit_signal("inventory_closed")

func add_clue_dummy():
	dummy = get_node("Clue").duplicate()
	dummy.get_node("ClueButton").set_normal_texture(null)
	dummy.get_node("ClueButton/Label").set_text("")
	dummy.get_node("ClueButton/points").set_text("")
	clue_parent.add_child(dummy)

func add_evidence_dummy():
	dummy_item = get_node("ItemClue").duplicate()
	dummy_item.get_node("ClueButton").set_normal_texture(null)
	dummy_item.get_node("ClueButton/Label").set_text("")
	dummy_item.get_node("ClueButton/points").set_text("")
	evidence_parent.add_child(dummy_item)

func open():
	instance_clues()
	#TO-DO:See if this is necessary:
	#yield(self, "clues_instanced")
	add_clue_dummy()
	add_evidence_dummy()
	show()
	game.add_hud(self)
	
	if puzzle_to_solve() != null:
		var green = Color(80.0/255.0, 200.0/255.0, 80.0/255.0)
		get_node("Menu/Suspects/SuspectControl/AnalysisBoard/Label").set("custom_colors/font_color", green)
	else:
		var gray = Color(40.0/255.0, 40.0/255.0, 40.0/255.0)
		get_node("Menu/Suspects/SuspectControl/AnalysisBoard/Label").set("custom_colors/font_color", gray)
	emit_signal("inventory_opened")

func open_fact_analysis():
	var puzzle = puzzle_to_solve()
	if puzzle == null:
		game.get_node("speech_dialogue_player").start(["", analysis_data.no_puzzle], vm.level.current_context, false)
		return
	if game.current_scene.get_name() != "Analysis":
		get_node("Menu/Options/menu").save_pressed("tempsave")
		game.change_scene_puzzle(["res://ui/FactAnalysis.tscn"], puzzle, vm.level.current_context)
		close()

func puzzle_to_solve():
	var puzzles = game.puzzles
	var use_this_puzzle = true
	for puzzle in puzzles.keys():
		if !puzzles[puzzle].is_solved:
			var clues =  puzzles[puzzle].clues
			for clue in clues:
				if !(clue in game.clues):
					use_this_puzzle = false
					break
			if use_this_puzzle:
				return puzzle
		use_this_puzzle = true
	return null

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
func clue_pressed(clue_id, is_item):
	if !vm.game.hud_layer.has_node("dialog"):
		var node = null
		if is_item and evidence_parent.has_node(clue_id):
			node = evidence_parent.get_node(clue_id)
		elif clue_parent.has_node(clue_id):
			node = clue_parent.get_node(clue_id)
		else:
			return
	
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
	if has_node(clue_id):
		var areas = get_node(clue_id).get_node("ClueButton/Area2D").get_overlapping_areas()
		for area in areas:
			if area.get_name().find("Notebook") != -1:
				dragging = false
				remove_child(curr_clue)
				curr_clue = null
				return
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
	var suspect_parent = get_node("Menu/Suspects/SuspectControl/ScrollContainer/HBoxContainer")
	if fact.has("supports") and suspect in fact["supports"]["clues"]:
		if relation_exists(clue_id, suspect_id, "supports"):
			game.get_node("speech_dialogue_player").start(["", analysis_data.found], vm.level.current_context, false)
			return
		var points = fact["points"]
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
		bar.get_node("Label").set_text("+" + str(bar.get_value()))
		instance_relation(clue_id, suspect_id, "supports")
		game.get_node("speech_dialogue_player").start(["", analysis_data.supports], vm.level.current_context, false)
		clues_used_on_suspects.append(clue_id)
		clean_clues(clue_id)
	elif fact.has("contradicts") and suspect in fact["contradicts"]["clues"]:
		if relation_exists(clue_id, suspect_id, "contradicts"):
			game.get_node("speech_dialogue_player").start(["", analysis_data.found], vm.level.current_context, false)
			return
		var points = fact["points"]
		var bar = suspect_parent.get_node(suspect_id).get_node("Sprite/ProgressBar")
		if (bar.get_progress_texture().get_name() == "progress_negative.PNG"):
			bar.set_value(bar.get_value() + points)
		elif (bar.get_value() - points) < 0:
			bar.set_progress_texture(load("res://ui/graphics/progress_negative.PNG"))
			bar.set_value(-1*(bar.get_value() - points))
		else:
			bar.set_value(bar.get_value() - points)
		bar.get_node("Label").set_text("-" + str(bar.get_value()))
		instance_relation(clue_id, suspect_id, "contradicts")
		game.get_node("speech_dialogue_player").start(["", analysis_data.contradicts], vm.level.current_context, false)
		clues_used_on_suspects.append(clue_id)
		clean_clues(clue_id)
	else:
		game.get_node("speech_dialogue_player").start(["", analysis_data.default], vm.level.current_context, false)
	if(int(suspect_parent.get_node(suspect_id).get_node("Sprite/ProgressBar/Label").get_text()) >= analysis_data.SUSPECT_THRESHOLD):
		vm.set_global(suspect, true)

func clean_clues(id):
	#add to list of things
	#only erase if it's not in another puzzle
	for puzzle in analysis_data.puzzles.keys():
		if id in analysis_data.puzzles[puzzle]["clues"] and analysis_data.puzzles[puzzle]["is_solved"] == false:
			return
	
	game.clues.erase(id)
	clue_parent.remove_child(clue_parent.get_node(id))

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
	print(game.clues)
	for clue in game.clues:
		if !is_item_clue(clue) and !clue_parent.has_node(clue):
			instance_clue(clue, null, null, false)
		elif is_item_clue(clue) and !evidence_parent.has_node(clue):
			instance_clue(clue, null, null, true)
	for clue in clue_parent.get_children():
		if !(clue.get_name() in game.clues):
			clue_parent.remove_child(clue)
	
	emit_signal("clues_instanced")

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
	
	node.get_node("ClueButton").connect("button_down", self, "clue_pressed", [clue_id, is_item])
	node.get_node("ClueButton").connect("button_up", self, "clue_released", [clue_id])
	
	if is_item:
		evidence_parent.add_child(node)
	else:
		clue_parent.add_child(node)

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
	
	clue_parent = get_node("Menu/Suspects/SuspectControl/TabContainer/Clues/VBoxContainer")
	evidence_parent = get_node("Menu/Suspects/SuspectControl/TabContainer/Evidence/VBoxContainer")
	analysis_data = get_node("AnalysisData")
	instance_clues()
	
	
	if game.puzzles.keys().size() < 1:
		game.puzzles = analysis_data.puzzles

	inventory = preload("res://game/data/inventory.gd")
	
	get_node("Menu/Suspects/SuspectControl/AnalysisBoard").connect("pressed", self, "open_fact_analysis")
