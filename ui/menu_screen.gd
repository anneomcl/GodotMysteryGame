extends "main_menu.gd"

func save():
	#TODO: Add more things to the "save" group as needed, will need loop in save_pressed
	var player = get_tree().get_nodes_in_group("save")[0]
	
	var save_dict = {
		file = player.get_filename(),
		parent = player.get_parent().get_name(),
		pos_x = player.get_pos().x,
		pos_y = player.get_pos().y,
		current_scene = game.current_scene.get_filename(),
		globals = vm.get_all_globals()
	}
	
	return save_dict

func save_pressed():
	var save_game = File.new()
	save_game.open_encrypted_with_pass("user://savegame.save", File.WRITE, "password")
	var node_data = save()
	save_game.store_line(node_data.to_json())
	save_game.close()
	close()
	
func quit_to_menu_pressed():
	close()
	game.change_scene(["res://scenes/test/main_menu.tscn"], vm.level.current_context)

func load_menu_pressed():
	load_pressed()
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
	get_node("save_game_menu").connect("pressed", self, "save_pressed")
	get_node("quit_to_menu").connect("pressed", self, "quit_to_menu_pressed")
	get_node("load_game_menu").connect("pressed", self, "load_menu_pressed")
