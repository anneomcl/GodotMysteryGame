var objects = {}
var res_cache

var game_size = Vector2()

var ui_layer
var hud_layer

var items = []
var clues = []
var relations = {}
var clue_positions = {}
var facts = {}
var analysis_camera_pos = Vector2(0, 0)
var analysis_camera_zoom = Vector2(1, 1)

var hud_stack = []
var ui_stack = []

var window_size = Vector2()

var current_scene
var current_player

var equipped
var failures = 0

var persist_scene = false

var vm
var animation

signal change_scene_finished

func register_object(name, val):
	objects[name] = val
	if name in vm.states:
		val.set_state(vm.states[name])
	else:
		val.set_state("default")
	if name in vm.actives:
		val.set_active(vm.actives[name])
	val.connect("exit_tree", self, "object_exit_scene", [name])

func get_object(name):
	if !(name in objects):
		return null

	return objects[name]

func object_exit_scene(name):
	return
	#if name != "player" and !persist_scene:
		#objects.erase(name)

func say(params, level):
	vm.set_ui_active(true)
	get_node("speech_dialogue_player").start(params, level, false)

func dialog(params, level):
	vm.set_ui_active(true)
	get_node("speech_dialogue_player").start(params, level, true)

func _process(time):
	check_screen()

func _input(event):
	if ui_stack.size() > 0:
		ui_stack[ui_stack.size()-1].input(event)

	elif hud_stack.size() > 0:
		hud_stack[hud_stack.size()-1].input(event)

	else:
		if event.is_action("inventory_toggle"):
			if event.is_pressed() && !event.is_echo(): #&& current_scene.get_name() != "Analysis":
				inventory_open()

		if event.is_action("menu_request"):
			if event.is_pressed() && !event.is_echo() && current_scene.get_name() != "Analysis":
				menu_open()

func menu_open():
	hud_layer.get_node("menu").open()

func inventory_open():
	hud_layer.get_node("inventory").open()
	
func inventory_close():
	hud_layer.get_node("inventory").close()

func inventory_set(name, p_enabled):
	# maybe not necessary? it can be global flags
	pass

func change_scene(params, context):
	print("change scene to ", params[0])
	# remove current scene
	if current_scene != null:
		current_scene.queue_free()
		current_scene = null

	var res = res_cache.get_resource(params[0])
	res_cache.clear()
	if res == null:
		print("error: unable to load new scene ", params[0])
		return
	var scene = res.instance()
	if scene == null:
		print("error: failed to instance new scene ", params[0])
		return
	get_node("/root").add_child(scene)
	set_current_scene(scene)
	emit_signal("change_scene_finished")
	vm.finished(context, false)

func start_new_game():
	vm.clear()
	var events = vm.compile("res://ui/start_menu.esc")
	vm.run_event(events["load"], {})

func execute_cutscene(scene):
	var events = vm.compile(scene)
	vm.run_event(events["load"], {})

func set_current_scene(p_scene):
	current_scene = p_scene

func set_current_player(p_player):
	current_player = p_player

func equip(name):
	if equipped == name:
		equipped = ""
		vm.set_value ("equipped", "=", "")
	else:
		equipped = name
		vm.set_value("equipped", "=", name)
	emit_signal("object_equipped", equipped)

func get_equipped():
	return equipped

func check_screen():
	var vs = OS.get_video_mode_size()
	if vs == window_size:
		return
	window_size = vs

	var rate = float(vs.x)/float(vs.y)
	var height = int(game_size.x / rate)
	get_tree().get_root().set_size_override(true,Vector2(game_size.x,height))
	get_tree().get_root().set_size_override_stretch(true)

	var m = Matrix32()
	var ofs = Vector2(0, (height - game_size.y) / 2)
	m[2] = ofs
	get_tree().get_root().set_global_canvas_transform(m)

func add_hud(p_node):
	hud_stack.push_back(p_node)
	vm.set_ui_active(true)

func remove_hud(p_node):
	if hud_stack.size() == 0 || hud_stack[hud_stack.size()-1] != p_node:
		print("warning: removing node from hud which is not at the top ", p_node.get_path())

	hud_stack.erase(p_node)
	vm.set_ui_active(hud_stack.size() != 0 || ui_stack.size() != 0)

func update_global_lists(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
		if(!clues.has(id)):
			clues.append(id)
	elif id.substr(0, 2) == "i/":
		id.erase(0, 2)
		if(!items.has(id)):
			items.append(id)

func _ready():
	res_cache = preload("res://globals/resource_queue.gd").new()
	res_cache.start()

	game_size = Vector2(Globals.get("display/game_width"), Globals.get("display/game_height"))

	vm = get_node("/root/vm")
	vm.game = self

	hud_layer = get_node("hud_layer")
	ui_layer = get_node("ui_layer")

	set_process(true)
	set_process_input(true)

	add_user_signal("object_equipped", ["name"])
	
	vm.connect("global_changed", self, "update_global_lists")