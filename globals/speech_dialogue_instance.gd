extends Control

export var mouse_enter_color = Color(1,1,0.3)
export var mouse_enter_shadow_color = Color(0.6,0.4,0)
export var mouse_exit_color = Color(1,1,1)
export var mouse_exit_shadow_color = Color(1,1,1)

var vm
var character
var character_name
var context
var cmd

var is_choice
var has_multiple_choices
var option_mapping = {}
var choice_size = 1
var choice_offset = 15
var avatar_scale = Vector2(.25, .25)

var container
var item
var button
var label

var animation
var ready = false
var option_selected = 0
var dialog_task

func input(event):
	if event.is_action_pressed("ui_accept"):
		if has_multiple_choices:
			selected(int(option_mapping[str(option_selected)]))
		else:
			selected(option_selected)
	if event.is_action_pressed("ui_up") or event.is_action_pressed("walk_up"):
		if option_selected == 0:
			return
		else:
			container.get_child(option_selected).get_node("cursor").hide()
			option_selected -= 1
			container.get_child(option_selected).get_node("cursor").show()
	if event.is_action_pressed("ui_down") or event.is_action_pressed("walk_down"):
		if option_selected == (choice_size - 1):
			return
		else:
			container.get_child(option_selected).get_node("cursor").hide()
			option_selected += 1
			container.get_child(option_selected).get_node("cursor").show()
	pass

func selected(n):
	if !ready:
		return
	option_selected = n
	if vm.globals.has("finish_event"):
		animation.play("hide")
	else:
		clear_dialogue()
		choice_size = 1
		if is_choice:
			vm.add_level(cmd[option_selected].params[1], false, dialog_task)
	ready = false

func add_speech(text, id):
	var it = item.duplicate()
	var but = it.get_node("button")
	var lab = but.get_node("label")
	var cur = it.get_node("cursor")
	lab.set_text(text)
	but.connect("pressed", self, "selected", [id])

	if is_choice:
		var height_ratio = Globals.get("platform/dialog_option_height")
		var size = it.get_custom_minimum_size()
		size.y = size.y * height_ratio
		but.set_size(size)
		handle_choice_offsets(it, but, lab, cur, choice_offset, id)
	else:
		cur.hide()

	container.add_child(it)
	
func handle_choice_offsets(it, but, lab, cur, offset, i):
	if has_multiple_choices:
		var new_pos = it.get_pos() + (Vector2(0, offset) * i)
		it.set_pos(new_pos)
		but.set_pos(new_pos)
		lab.set_pos(new_pos + Vector2(50, 0))
		cur.set_pos(new_pos + Vector2(0, offset) * (i + 1)) #needs to match cursor offset

		if (i == 0):
			option_selected = 0
			cur.show() #the first option is defaulted to selected
		else:
			cur.hide()
			choice_size += 1

func add_choices():
	var i = 0
	var j = 0
	has_multiple_choices = false
	for choice in cmd:
		if !vm.test(choice):
			option_mapping[str(i)] = str(i + 1)
			i += 1
			continue
		if i > 0:
			option_mapping[str(i)] = str(int(option_mapping[str(i - 1)]) + 1)
		else:
			option_mapping[str(0)] = str(0)
		add_speech(choice.params[0], j)
		i += 1
		j += 1
		has_multiple_choices = true

func create_new_avatar(avatar, avatar_id):
	var avatar_node = Sprite.new()
	avatar_node.set_texture(avatar)
	avatar_node.set_name(avatar_id)
	avatar_node.set_scale(avatar_scale)
	return avatar_node

func display_portrait(avatar_id):
	if has_node("anchor/avatars"):
		
		var avatar_path = "res://character/avatars/"
		var avatars = get_node("anchor/avatars")
		var avatar
		
		if avatar_id != null:
			avatar = load(avatar_path + avatar_id + ".png")
			if !avatars.has_node(avatar_id):
				var avatar_node = create_new_avatar(avatar, avatar_id)
				avatars.add_child(avatar_node)
		elif is_choice:
			avatar_id = null
		else:
			avatar_id = "default"
		
		for i in range(avatars.get_child_count()):
			var c = avatars.get_child(i)
			if c.get_name() == avatar_id:
				c.show()
			else:
				c.hide()

#To create a custom event:
#params: [character name, speech], null, false (not a choice, just dialogue)
func start(params, p_context, p_is_choice):
	context = p_context
	dialog_task = vm.task_current
	is_choice = p_is_choice
	
	if is_choice:
		cmd = params[0]
		add_choices()
	else:
		character_name = params[0]
		character = vm.game.get_object(params[0])
		if character != null:
			character.set_speaking(true)
		add_speech(params[1], 0)
	
	var avatar_id = null
	if(params.size() > 2):
		avatar_id = params[2]
	display_portrait(avatar_id)
	
	if(character_name != null):
		get_node("anchor/name").set_text(character_name)
	
	ready = false
	animation.play("show_basic")
	animation.seek(0, true)
	
func _on_mouse_enter(button):
	button.get_node("label").add_color_override("font_color", mouse_enter_color)
	button.get_node("label").add_color_override("font_color_shadow", mouse_enter_shadow_color)
	
func _on_mouse_exit(button):
	button.get_node("label").add_color_override("font_color", mouse_exit_color)
	button.get_node("label").add_color_override("font_color_shadow", mouse_exit_shadow_color)

func stop():
	vm.game.hide_clue_received(false)
	hide()
	while container.get_child_count() > 0:
		var c = container.get_child(0)
		container.remove_child(c)
		c.free()
	vm.request_autosave()
	_queue_free()

func game_cleared():
	_queue_free()

func _queue_free():
	get_node("/root/game").remove_hud(self)
	queue_free()

func clear_dialogue():
	vm.finished(context, false)
	if !is_choice and character != null:
		character.set_speaking(false)
	stop()

func anim_finished():
	var cur = animation.get_current_animation()
	if cur == "show_basic":
		ready = true
	elif cur == "hide":
		clear_dialogue()
	else:
		ready = true
	
func _ready():
	hide()
	
	vm = get_tree().get_root().get_node("vm")
	
	container = get_node("anchor/scroll/container")
	container.set_stop_mouse(false)
	
	item = get_node("item")
	button = item.get_node("button")
	label = button.get_node("label")
	
	item.set_stop_mouse(false)
	button.set_stop_mouse(false)
	label.set_stop_mouse(false)
	
	call_deferred("remove_child", item)
	
	animation = get_node("animation")
	animation.connect("finished", self, "anim_finished")
	
	self.connect("exit_tree", self, "clear_dialogue")
	add_to_group("game")