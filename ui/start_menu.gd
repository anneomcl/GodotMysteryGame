extends Control

var vm
var game

func input(event):
	if event.is_echo():
		return
	if !event.is_pressed():
		return

func new_pressed():
	vm.clear()
	var events = vm.compile("res://game/game.esc")
	vm.run_event(events["load"], {})

func check_if_scene_persists(name):
	if(name == game.current_scene.get_filename()):
		game.persist_scene = true
	else:
		game.persist_scene = false

func load_globals(globals, curr_scene):
	for item in globals:
		vm.set_global(item, globals[item])
		if(globals[item] == true and item.substr(0, 1) == "i"):
			item.erase(0, 2)
			#TODO: Check when and if items need to be set_active(false)
			#var item_node = curr_scene.get_node(item)
			#item_node.set_active(false)

func load_pressed(save_name):
	var save = File.new()
	if !save.file_exists("user://" + save_name + ".save"):
		return

	var nodes = get_tree().get_nodes_in_group("save")
	for item in nodes:
		item.call_deferred("queue_free")
	
	var err = save.open_encrypted_with_pass("user://" + save_name + ".save", File.READ, "password")
	var line = {}
	line.parse_json(save.get_line())
	
	while(!save.eof_reached()):
		var scene_name = line["current_scene"]
		check_if_scene_persists(scene_name)
		game.change_scene([scene_name], vm.level.current_context)
		
		var curr_scene = game.current_scene
		
		var obj
		if(curr_scene.has_node("player")):
			obj = curr_scene.get_node("player")
		else:
			obj = load(line["file"]).instance()
			curr_scene.add_child(obj)
		obj.set_pos(Vector2(line["pos_x"], line["pos_y"]))

		if (save_name != "tempsave"):
			vm.globals = line["globals"]
			
			load_globals(line["globals"], curr_scene)
			
			var clues = line["clues"]
			if (clues != null):
				vm.game.clues = clues
			else:
				vm.game.clues = []
	
			var relations = line["relations"]
			if (relations != null):
				vm.game.relations = relations
			else:
				vm.game.relations = {}
	
			var facts = line["facts"]
			if (facts != null):
				vm.game.facts = facts
			else:
				vm.game.facts = {}
	
			var items = line["items"]
			if (items != null):
				vm.game.items = items
			else:
				vm.game.items = []
	
			var clue_positions_x = line["clue_positions_x"]
			var clue_positions_y = line["clue_positions_y"]
			if (clue_positions_x != null and clue_positions_y != null):
				vm.game.clue_positions = combine_clue_positions(clue_positions_x, clue_positions_y)
			else:
				vm.game.clue_positions = {}
	
			var analysis_camera_pos_x = line["analysis_camera_pos_x"]
			var analysis_camera_pos_y = line["analysis_camera_pos_y"]
			if (analysis_camera_pos_x != null and analysis_camera_pos_y != null):
				vm.game.analysis_camera_pos = Vector2(analysis_camera_pos_x, analysis_camera_pos_y)
			else:
				vm.game.analysis_camera_pos = Vector2(0, 0)
				
			var analysis_camera_zoom_x = line["analysis_camera_zoom_x"]
			var analysis_camera_zoom_y = line["analysis_camera_zoom_y"]
			if (analysis_camera_zoom_x != null and analysis_camera_zoom_y != null):
				vm.game.analysis_camera_zoom = Vector2(analysis_camera_zoom_x, analysis_camera_zoom_y)
			else:
				vm.game.analysis_camera_zoom = Vector2(1, 1)

		line.parse_json(save.get_line())

	save.close()

func combine_clue_positions(x, y):
	var ret = {}
	if (x.keys().size() != y.keys().size()):
		return {}
	else:
		for clue in x.keys():
			ret[clue] = (Vector2(x[clue], y[clue]))
	
	return ret
			

func _ready():
	if(find_node("new_game")):
		get_node("new_game").connect("pressed", self, "new_pressed")
	if(find_node("load_game")):
		get_node("load_game").connect("pressed", self, "load_pressed", ["savegame"])
	
	vm = get_tree().get_root().get_node("vm")
	game = get_tree().get_root().get_node("game")

	set_process_input(true)

	add_to_group("ui")