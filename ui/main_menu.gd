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

func load_pressed():
	var save = File.new()
	if !save.file_exists("user://savegame.save"):
		return

	var nodes = get_tree().get_nodes_in_group("save")
	for item in nodes:
		item.call_deferred("queue_free")
	
	var err = save.open_encrypted_with_pass("user://savegame.save", File.READ, "password")
	var line = {}
	line.parse_json(save.get_line())
	
	while(!save.eof_reached()):
		var scene_name = line["current_scene"]
		check_if_scene_persists(scene_name)
		game.change_scene([scene_name], vm.level.current_context)
		
		var curr_scene = game.current_scene
		load_globals(line["globals"], curr_scene)
		
		var obj
		if(curr_scene.has_node("player")):
			obj = curr_scene.get_node("player")
		else:
			obj = load(line["file"]).instance()
			curr_scene.add_child(obj)
		
		obj.set_pos(Vector2(line["pos_x"], line["pos_y"]))
		line.parse_json(save.get_line())

	save.close()

func _ready():
	if(find_node("new_game")):
		get_node("new_game").connect("pressed", self, "new_pressed")
	if(find_node("load_game")):
		get_node("load_game").connect("pressed", self, "load_pressed")
	
	vm = get_tree().get_root().get_node("vm")
	game = get_tree().get_root().get_node("game")

	set_process_input(true)

	add_to_group("ui")