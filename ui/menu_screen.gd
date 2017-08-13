extends "start_menu.gd"

func save():
	var player = get_tree().get_nodes_in_group("save")[0]
	
	var save_dict = {
		file = player.get_filename(),
		parent = player.get_parent().get_name(),
		pos_x = player.get_pos().x,
		pos_y = player.get_pos().y,
		current_scene = game.current_scene.get_filename(),
		globals = vm.get_all_globals(),
		clues = vm.game.clues,
		relations = vm.game.relations,
		facts = vm.game.facts,
		items = vm.game.items,
		clue_positions_x = process_clue_positions(false),
		clue_positions_y = process_clue_positions(true),
		analysis_camera_pos_x = vm.game.analysis_camera_pos.x,
		analysis_camera_pos_y = vm.game.analysis_camera_pos.y,
		analysis_camera_zoom_x = vm.game.analysis_camera_zoom.x,
		analysis_camera_zoom_y = vm.game.analysis_camera_zoom.y,
		globals = vm.globals
	}
	
	return save_dict

func process_clue_positions(isY):
	var ret = {}
	for clue in vm.game.clue_positions.keys():
		if isY:
			ret[clue] = vm.game.clue_positions[clue].y
		else:
			ret[clue] = vm.game.clue_positions[clue].x
	return ret

func save_pressed(save_name):
	var save_game = File.new()
	save_game.open_encrypted_with_pass("user://" + save_name + ".save", File.WRITE, "password")
	var node_data = save()
	save_game.store_line(node_data.to_json())
	save_game.close()
	close()
	
func quit_to_menu_pressed():
	close()
	game.change_scene(["res://scenes/test/start_menu.tscn"], vm.level.current_context)

func load_menu_pressed():
	load_pressed("savegame")
	close()

func input(event):
	if event.is_echo():
		return
	if !event.is_pressed():
		return
	if event.is_action("menu_request"):
		close()

func close():
	hide()
	game.remove_hud(self)

func open():
	show()
	game.add_hud(self)

func _ready():
	get_node("save_game_menu").connect("pressed", self, "save_pressed", ["savegame"])
	get_node("quit_to_menu").connect("pressed", self, "quit_to_menu_pressed")
	get_node("load_game_menu").connect("pressed", self, "load_menu_pressed")
