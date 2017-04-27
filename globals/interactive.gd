tool

var vm
var animation

var sprites = []
var shapes = []

var anim_scale_override
var anim_notify

var state = ""
export var active = true setget set_active,get_active

export var global_id = ""
export var talk_animation = "talk"

func modulate(color):
	for s in sprites:
		s.set_modulate(color)

func play_anim(p_anim, p_notify = null, p_reverse = false, p_flip = null):

	if typeof(p_notify) != typeof(null) && (!has_node("animation") || !get_node("animation").has_animation(p_anim)):
		print("skipping cut scene '", p_anim, "'")
		vm.finished(p_notify, false)
		#_debug_states()
		return

	if p_flip != null && self extends Node2D:
		var scale = get_scale()
		set_scale(scale * p_flip)
		anim_scale_override = p_flip
	else:
		anim_scale_override = null

	if p_reverse:
		get_node("animation").play(p_anim, -1, -1, true)
	else:
		get_node("animation").play(p_anim)
	anim_notify = p_notify

func set_state(p_state, p_force = false):
	printt("set state ", global_id, state, p_state, p_force)
	#print_stack()
	if state == p_state && !p_force:
		return
	if animation != null:
		animation.stop()
	state = p_state
	if animation != null:
		printt("has animation", animation.has_animation(p_state))
		if animation.is_playing() && animation.get_current_animation() == p_state:
			return
		if animation.has_animation(p_state):
			printt("playing animation ", p_state)
			animation.play(p_state)

func set_speaking(p_speaking):
	printt("item set speaking! ", global_id, p_speaking, state)
	#print_stack()
	if !has_node("animation"):
		return
	if talk_animation == "":
		return
	if p_speaking:
		if get_node("animation").has_animation(talk_animation):
			get_node("animation").play(talk_animation)
			get_node("animation").seek(0, true)
		#else:
		#	set_state(state, true)
	else:
		if get_node("animation").is_playing():
			get_node("animation").stop()
		set_state(state, true)
	pass

func set_active(p_active):
	active = p_active
	if p_active:
		show()
	else:
		hide()

	set_trigger_shapes(p_active)

func set_trigger_shapes(p_active):
	printt("set trigger shapes ", shapes.size())
	for shape in shapes:
		printt("shape ", shape.get_name(), p_active)
		shape.set_trigger(!p_active)
		
func get_active():
	return active

func _find_sprites(p = null):
	if p.is_type("Sprite") || p.is_type("AnimatedSprite") || p.is_type("TextureFrame") || p.is_type("TextureButton"):
		sprites.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_sprites(p.get_child(i))

func _find_shapes(p = null):
	if p == null:
		p = self
	if p.is_type("CollisionShape2D"):
		shapes.push_back(p)
	for i in range(0, p.get_child_count()):
		_find_shapes(p.get_child(i))

func anim_finished():
	var stack = vm.tasks[vm.task_current].stack
	var context = stack[stack.size()-1]
	vm.finished(context, false)

func _ready():
	_find_sprites(self)
	_find_shapes(self)

	if get_tree().is_editor_hint():
		return
	if has_node("animation"):
		animation = get_node("animation")
	vm = get_node("/root/vm")

	if global_id != "":
		vm.game.register_object(global_id, self)

	if has_node("animation"):
		get_node("animation").connect("finished", self, "anim_finished")
