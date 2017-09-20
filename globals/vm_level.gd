var global = null
var vm
var current_context

func check_obj(name, cmd):
	var obj = vm.game.get_object(name)
	if obj == null:
		vm.report_errors("", ["Global id "+name+" not found for " + cmd])
		return false
	return true

func _walk(params, block):
	if !check_obj(params[0], "walk"):
		return vm.state_return
	if !check_obj(params[1], "walk"):
		return vm.state_return
	var tpos = vm.game.get_object(params[1]).get_pos()

	if vm.tasks[vm.task_current].skipped:
		vm.game.get_object(params[0]).teleport_pos(tpos)
		return vm.state_return

	var speed = 0
	if params.size() > 2:
		speed = int(params[2])
	if block:
		current_context.waiting = true
		var obj = vm.game.get_object(params[0])
		obj.walk(tpos, speed, current_context, params[3], params[4], params[5], params[6], int(params[7]))
		return vm.state_yield
	else:
		vm.game.get_object(params[0]).walk(tpos, speed, current_context, params[3], params[4], params[5], params[6], int(params[7]))
		return vm.state_return

func camera_to_player(params):
	var obj = vm.game.get_object(params[0])
	var tween = vm.game.current_player.get_node("Camera2D/tween").duplicate()
	obj.add_child(tween)
	current_context.waiting = true
	tween.interpolate_property(obj, "transform/pos", obj.get_pos(), Vector2(0, 0), 1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()

### commands

func set_global(params):
	vm.set_global(params[0], params[1])
	return vm.state_return

func debug(params):
	for p in params:
		printraw(p)
	printraw("\n")
	return vm.state_return

func set_value(params):
	vm.set_value(params[0], params[1], params[2])
	return vm.state_return

func set_random_value(params):
	vm.set_random_value(params[0], params[1], params[2])
	return vm.state_return

func anim(params):
	if !check_obj(params[0], "anim"):
		return vm.state_return
	var obj = vm.game.get_object(params[0])
	var anim_id = params[1]
	var reverse = false
	if params.size() > 2:
		reverse = params[2]
	var flip = Vector2(1, 1)
	if params.size() > 3 && params[3]:
		flip.x = -1
	if params.size() > 4 && params[4]:
		flip.y = -1
	obj.play_anim(anim_id, null, reverse, flip)
	return vm.state_return

func set_state(params):
	var obj = vm.game.get_object(params[0])
	if obj != null:
		obj.set_state(params[1])
	vm.set_state(params[0], params[1])
	return vm.state_return

func say(params):
	if vm.tasks[vm.task_current].skipped:
		return vm.state_return
	if !check_obj(params[0], "say"):
		return vm.state_return
	current_context.waiting = true
	vm.game.say(params, current_context)
	return vm.state_yield

func dialog(params):
	vm.cancel_skip()
	current_context.waiting = true
	vm.game.dialog(params, current_context)
	return vm.state_yield

func accuse(params):
	current_context.waiting = true
	vm.game.accuse(params, current_context)
	return vm.state_yield

#Parameters: "cut_scene" <anim_id> <flipx?> <flipy?>
func cut_scene(params):
	if !check_obj(params[0], "cut_scene"):
		return vm.state_return

	if vm.tasks[vm.task_current].skipped:
		# it's up to set_state to leave this correctly
		return vm.state_return

	var obj = vm.game.get_object(params[0])
	var anim_id = params[1]
	var reverse = false
	if params.size() > 2:
		reverse = params[2]
	var flip = Vector2(1, 1)
	if params.size() > 3 && params[3]:
		flip.x = -1
	if params.size() > 4 && params[4]:
		flip.y = -1
	current_context.waiting = true
	obj.play_anim(anim_id, current_context, reverse, flip)
	return vm.state_yield

func branch(params):
	return vm.add_level(params, false, current_context.task)

func branch_else(params):
	return vm.add_level(params, false, current_context.task)

func inventory_add(params):
	vm.game.inventory_set(params[0], true)
	return vm.state_return

func inventory_remove(params):
	vm.game.inventory_set(params[0], false)
	return vm.state_return
	
func inventory_open(params):
	vm.emit_signal("open_inventory", params[0])

func set_active(params):
	var obj = vm.game.get_object(params[0])
	if obj != null:
		obj.set_active(params[1])
	vm.set_active(params[0], params[1])
	return vm.state_return

func stop(params):
	return vm.state_break

func repeat(params):
	return vm.state_repeat

func wait(params):
	return vm.wait(params, current_context)

func teleport(params):
	if !check_obj(params[0], "teleport"):
		return vm.state_return
	if !check_obj(params[1], "teleport"):
		return vm.state_return
	vm.game.get_object(params[0]).teleport(vm.game.get_object(params[1]))
	return vm.state_return

func teleport_pos(params):
	if !check_obj(params[0], "teleport_pos"):
		return vm.state_return
	vm.game.get_object(params[0]).teleport_pos(int(params[1]), int(params[2]))
	return vm.state_return

func walk(params):
	return _walk(params, false)

func walk_block(params):
	return _walk(params, true)

func change_scene(params):
	# looking for localized string format in scene. this should be somewhere else
	var sep = params[0].find(":\"")
	if sep >= 0:
		var path = params[0].substr(sep + 2, params[0].length() - (sep + 2))
		vm.game.call_deferred("change_scene", [path], current_context)
	else:
		vm.game.call_deferred("change_scene", params, current_context)

	current_context.waiting = true
	return vm.state_yield

func queue_scene(params):
	vm.game.res_cache.queue_resource(params[0])

func spawn(params):
	return vm.game.spawn(params)

func jump(params):
	vm.jump(params[0])
	return vm.state_jump

func sched_event(params):
	var time = params[0]
	var obj = params[1]
	var event = params[2]
	if !check_obj(obj, "sched_event"):
		return
	var o = vm.game.get_object(obj)
	if !(event in o.event_table):
		vm.report_errors("", ["Event "+event+" not found on object " + obj + " for sched_event."])
		return
	vm.sched_event(time, obj, event)

func custom(params):
	var node = vm.game.get_node(params[0])
	if node == null:
		vm.report_errors("", ["Node not found for custom: "+params[0]])

	if params.size() > 2:
		node.call(params[1], params)
	else:
		node.call(params[1])

func camera_set_target(params):
	var speed = params[0]
	var targets = []
	for i in range(1, params.size()):
		targets.push_back(params[i])
	vm.game.camera_set_target(speed, targets)

func camera_set_pos(params):
	var speed = params[0]
	var pos = Vector2(params[1], params[2])
	vm.game.camera_set_target(speed, pos)

func set_globals(params):
	var pat = params[0]
	var val = params[1]
	vm.set_globals(pat, val)

func autosave(params):
	vm.game.request_autosave()

func queue_resource(params):
	var path = params[0]
	var in_front = false
	if params.size() > 1:
		in_front = params[1]

	vm.game.res_cache.queue_resource(path, in_front)

func queue_animation(params):
	var obj = params[0]
	var anim = params[1]
	var in_front = false
	if params.size() > 2:
		in_front = params[2]

	if !check_obj(obj, "queue_animation"):
		return vm.state_return

	obj = vm.game.get_object(obj)
	var paths = obj.anim_get_ph_paths(anim)
	for p in paths:
		vm.game.res_cache.queue_resource(p, in_front)

	return vm.state_return

func game_over(params):
	var continue_enabled = params[0]
	var show_credits = false
	if params.size() > 1:
		show_credits = params[1]
	vm.call_deferred("game_over", continue_enabled, show_credits, current_context)
	current_context.waiting = true
	return vm.state_yield

### end command

func run(context):
	var cmd = context.instructions[context.ip]
	if cmd.name == "label":
		return vm.state_return

	if !vm.test(cmd):
		return vm.state_return
	#print("name is ", cmd.name)
	#if !(cmd.name in self):
	#	vm.report_errors("", ["Unexisting command "+cmd.name])

	if cmd.name == "branch":
		context.branch_run = true
	elif cmd.name == "branch_else":
		if context.branch_run:
			return vm.state_return
		else:
			context.branch_run = true
	else:
		context.branch_run = false

	var params
	if !("no_eval" in vm.compiler.commands[cmd.name]) || !vm.compiler.commands[cmd.name].no_eval:
		params = []
		for p in cmd.params:
			params.push_back(vm.eval_value(p))
	else:
		params = cmd.params

	#printt(" calling cmd ", cmd.name, _unpack(cmd.params))
	return call(cmd.name, params)


func resume(context):
	current_context = context
	if context.waiting:
		return vm.state_yield
	if context.aborted:
		context.ip = 0
		return vm.state_return
	var count = context.instructions.size()
	while context.ip >= 0 && context.ip < count:
		var stack = vm.tasks[vm.task_current].stack
		var top = stack.size()

		var ret = run(context)
		context.ip += 1

		if top < stack.size():
			return vm.state_call
		if ret == vm.state_yield:
			context.waiting = true
			return vm.state_yield
		if ret == vm.state_call:
			return vm.state_call
		if ret == vm.state_break:
			if context.break_stop:
				break
			else:
				return vm.state_break
		if ret == vm.state_repeat:
			context.ip = 0
		if ret == vm.state_jump:
			return vm.state_jump
	context.ip = 0
	return vm.state_return

func set_vm(p_vm):
	vm = p_vm

func _init():
	#print("*************** vm level init")
	#vm = get_tree().get_singleton("vm")
	pass
