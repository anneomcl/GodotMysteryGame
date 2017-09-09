var objects = {}
var res_cache

var game_size = Vector2()

var ui_layer
var hud_layer

var indicator

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
	get_node("speech_dialogue_player").start(params, level, false)

func dialog(params, level):
	get_node("speech_dialogue_player").start(params, level, true)

func _process(time):
	check_screen()

func hide_clue_received(animate):
	if indicator != null:
		if animate:
			animation.play("fade_out_indicator")
		indicator.hide()

func show_clue_received(id):
	if id.substr(0, 2) == "c/" and indicator != null:
		indicator.show()
		animation.play("fade_in_indicator")

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

func prompt_judge():
	#TO-DO: trigger judge dialogue/cutscene
	#now trigger the cutscene by manually calling "use" on the judge
	#later, may want to make sure different judge scripts are 
	#loaded based on different levels (change esc script in Judge object)
	var judge = get_tree().get_root().get_node("test_scene/Judge")
	judge.interact(null)

func accuse(character_name, context):
	
	#Set the guilt percentage bar.
	#TO-DO: snap bar to the top of the camera screen
	var progress_bar = get_node("../test_scene/ProgressBar")
	progress_bar.set_hidden(false)
	progress_bar.set_percent_visible(true)
	
	#Set values to interface with the Judge esc script.
	vm.set_value("points", "=", "0")
	vm.set_value("strikes", "=", "0")
	var global_name
	var judge = get_tree().get_root().get_node("test_scene/Judge")
	var judge_initial_position = judge.get_pos()
	
	#Initialize the accusation sequence.
	prompt_judge()
	yield(get_node("../vm"), "esc_finished")
	
	#Keep prompting for evidence until win, lose, or quit.
	while(int(vm.values["points"]) < 90 && int(vm.values["strikes"]) < 3):
		yield(get_node("hud_layer/inventory"), "inventory_closed")
		var  curr = get_equipped() 
		if(curr != null):
			if(global_name != null):
				vm.set_global(global_name, false)
			global_name = get_equipped()
			global_name = global_name.replace("c/", "")
			global_name = global_name.replace("i/", "")
			vm.set_global(global_name, true)
		else:
			#If nothing is equipped, prompt player:
			#No evidence is equipped. Are you sure you'd
			#like to end the trial?
			#If yes, then add a failure (3 failures = game over)
			#If no, prompt the inventory again
			print("Quit trial?")
			failures += 1
			break
		
		#Evaluate the presented evidence.
		vm.set_global("esc_finished", false)
		prompt_judge()
		yield(get_node("../vm"), "esc_finished")
		
		var truth = progress_bar.get_value()
		progress_bar.set_value(truth + 10)
		
		hud_layer.get_node("inventory").update_items(vm.globals)
		
	#Reset the progress bar and the judge.
	progress_bar.set_hidden(true)
	var judge = get_tree().get_root().get_node("test_scene/Judge")
	judge.set_pos(judge_initial_position)
	judge.hide()
	
	#End conditions.
	if(failures == 3):
		print("Game Over")
		print ("Restart level, reset from beginning")
	
	if(int(vm.values["points"]) >=90 ):
		print("Guilt percentage bar disappears")
		print("Victory cutscene after completing accusation.")
		print("Load new cutscene, area, level, etc.")
	
	if(int(vm.values["strikes"]) > 2):
		print("Guilt percentage bar disappears")
		print("Losing cutscene")
		print("Reset values and return to investigation")
		failures += 1
	
	vm.finished(context, false)

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
	
	animation = get_node("hud_layer/animation")
	indicator = get_node("hud_layer/clue_indicator")
	vm.connect("global_changed", self, "show_clue_received")
	