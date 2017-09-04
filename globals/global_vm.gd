var tasks = []
var task_current = -1

var timers = []

var globals = {}
var values = {}
var states = {}
var actives = {}

var event_queue = []

var paused = false
var loading_game = false

var game

var compiler
var level

const state_return = 0
const state_yield = 1
const state_break = 2
const state_repeat = 3
const state_call = 4
const state_jump = 5

var last_event_id = 0

var ui_active = false

#delete
signal esc_finished
signal global_changed

func set_ui_active(p_active):
	ui_active = p_active

func add_level(p_level, p_root, p_task):
	tasks[task_current].stack.push_back(instance_level(p_level, null, p_root, p_task))
	return state_call

func instance_level(p_level, p_params, p_root, p_task):
	var level = { "ip": 0, "instructions": p_level, "waiting": false, "wait_reason": "", "break_stop": p_root, "labels": {}, "branch_run": false, "aborted": false, "task": p_task }
	if p_params != null:
		level.params = p_params
	for i in range(p_level.size()):
		if p_level[i].name == "label":
			var lname = p_level[i].params[0]
			level.labels[lname] = i
	return level

func _new_event_id():
	last_event_id += 1
	return last_event_id

func run_event(event, params, p_prio = 0):
	var id = _new_event_id()
	var task = { "stack": [], "stopped": false, "cutscene_mode": false, "skipped": false, "prio": p_prio, "id": id }
	task.stack.push_back(instance_level(event.level, params, true, id))

	var pos = tasks.size()
	var count = 0
	for t in tasks:
		var prio = 0
		if "prio" in t:
			prio = t.prio
		if prio > p_prio:
			pos = count
			break
		count += 1

	tasks.insert(pos, task)

	return id

func event_is_running(p_id):
	for t in tasks:
		if t.id == p_id:
			return true

	return false

func stop_event(p_id):
	for t in tasks:
		if t.id == p_id:
			t.stopped = true
			return

func finished(p_context, p_abort):
	p_context.waiting = false
	p_context.aborted = p_abort

func _process(time):
	check_timers(time)
	run()

func run_top():
	var stack = tasks[task_current].stack
	var top = stack[stack.size()-1]
	var ret = level.resume(top)
	if ret == state_return || ret == state_break:
		stack.remove(stack.size()-1)
	return ret

func run():
	if paused:
		return
	if tasks.size() == 0:
		return

	var i = 0
	while i < tasks.size():
		if tasks[i].stopped:
			i += 1
			continue
		var stack = tasks[i].stack
		task_current = i
		while stack.size() > 0:
			var ret = run_top()
			if ret == state_yield:
				break
			if ret == state_break:
				while stack.size() > 0 && !(stack[stack.size()-1].break_stop):
					stack.remove(stack.size()-1)
				stack.remove(stack.size()-1)
		i += 1
	task_current = -1

	var i = tasks.size()
	while i > 0:
		i -= 1
		if tasks[i].stopped || tasks[i].stack.size() == 0:
			# deal with whoever is waiting on this
			tasks.remove(i)

func compile_str(p_str):
	var ev_table

	var errors = []
	ev_table = compiler.compile_str(p_str, errors)
	if errors.size() > 0:
		call_deferred("report_errors", "str", errors)

	return ev_table

func compile(p_path):

	var ev_table

	if p_path.find(".gd") != -1:
		var res = ResourceLoader.load(p_path)
		if res == null:
			return null
		ev_table = res.new().get_events()
	elif p_path.find(".bin") != -1:
		var file = File.new()
		file.open(p_path, file.READ)
		ev_table = file.get_var()
		file.close()
	else:
		var errors = []
		ev_table = compiler.compile(p_path, errors)
		if errors.size() > 0:
			call_deferred("report_errors", p_path, errors)

	return ev_table

func report_errors(p_path, errors):
	print("Errors in file "+p_path+":\n\n")
	for e in errors:
		print(e)

func jump(p_label):
	var stack = tasks[task_current]
	while stack.size() > 0:
		var top = stack[stack.size()-1]
		printt("top labels: ", top.labels, p_label)
		if p_label in top.labels:
			top.ip = top.labels[p_label]
			return
		else:
			if top.break_stop || stack.size() == 1:
				report_errors("", ["Label not found: "+p_label+", can't jump"])
				stack.remove(stack.size()-1)
				break
			else:
				stack.remove(stack.size()-1)


func test(cmd):
	if "if_true" in cmd:
		for i in range(cmd.if_true.size()):
			if !check_global(cmd.if_true[i]):
				return false
	if "if_false" in cmd:
		for i in range(cmd.if_false.size()):
			if check_global(cmd.if_false[i]):
				return false
	if "cond_values" in cmd:
		for i in range(cmd.cond_values.size()):
			if !check_condition(cmd.cond_values[i]):
				return false

	return true

func check_global(name):
	var val = eval_value(name)
	if typeof(val) == TYPE_STRING:
		return get_global(val)
	else:
		return val

func get_global(name):
	return (name in globals) && globals[name]

func get_all_globals():
	return globals

func set_global_gd(name, val, indicate):
	if indicate:
		game.show_clue_received()
	else:
		game.hide_clue_received(false)
	set_global(name, val)

func set_global(name, val):
	globals[name] = val
	emit_signal("global_changed", name)
	print("set " + name + " to " + str(val))
	
	if(name == "esc_finished" && val == true):
		emit_signal("esc_finished")

func eval_value(name):
	var t = typeof(name)
	if t == TYPE_STRING:
		return name
	elif t == TYPE_ARRAY:
		if name[0] == compiler.val_localized:
			var ptext = TranslationServer.translate(name[1])
			if ptext != name[1]:
				return ptext
			else:
				return name[2]

		elif name[0] == compiler.val_local:
			if task_current != -1:
				# look for params in current task
				var stack = tasks[task_current].stack
				var i = stack.size()
				while i:
					i -= 1
					if "params" in stack[i] && name[1] in stack[i].params:
						return stack[i].params[name[1]]
			else:
				return null
		elif name[0] == compiler.val_global:
			if name[1] in values:
				return values[name[1]]

	return name

func check_condition(cond):
	var lval = eval_value(cond[0])
	if lval == null:
		report_errors("", ["Unknown value " + cond[0]])
		return false
	var rval = eval_value(cond[2])
	if rval == null:
		report_errors("", ["Unknown value " + rval])
		return false

	var frval = float(rval)
	var flval = float(lval)

	if cond[1] == "==":
		return flval == frval
	elif cond[1] == "!=":
		return flval != frval
	elif cond[1] == "<=":
		return flval <= frval
	elif cond[1] == "<":
		return flval < frval
	elif cond[1] == ">=":
		return flval >= frval
	elif cond[1] == ">":
		return flval > frval
	elif cond[1] == "()":
		return str(rval).find(str(lval)) >= 0
	else:
		report_errors("", ["Unknown operator "+cond[1]+" for comparison."])
		return false

func set_value(name, opr, val):
	printt("set value ", name, opr, val)
	if val == "":
		values[name] = val
		return
	if opr == "=":
		values[name] = val
	elif opr == "+=":
		values[name] = int(values[name]) + int(val)
	elif opr == "-=":
		values[name] = int(values[name]) - int(val)
	elif opr == "*=":
		values[name] = int(values[name]) * int(val)
	elif opr == "/=":
		values[name] = int(values[name]) / int(val)
	else:
		report_errors("", "Unknown operator "+opr+" for assigning")

func set_state(name, state):
	states[name] = state

func wait(time, context):
	var t = [time, context]
	timers.push_back(t)
	context.waiting = true
	context.wait_reason = "wait"

	return state_yield

func check_timers(time):
	var i = timers.size()
	while i > 0:
		i -= 1
		var t = timers[i]
		t[0] -= time
		if t[0] <= 0:
			finished(t[1], false)
			timers.remove(i)

func can_interact():
	return tasks.size() == 0 && !ui_active

func check_event_queue(time):
	for e in event_queue:
		if e[0] > 0:
			e[0] -= time

	if !can_interact():
		return

	var i = event_queue.size()
	while i:
		i -= 1
		if event_queue[i][0] <= 0:
			var obj = get_object(event_queue[i][1])
			run_event(obj.event_table[event_queue[i][2]])
			event_queue.remove(i)
			break

func sched_event(time, obj, event):
	event_queue.push_back([time, obj, event])

func set_active(name, active):
	actives[name] = active

func cancel_skip():
	for t in tasks:
		if t.skipped:
			t.skipped = false

func request_autosave():
	pass

func clear():
	get_tree().call_group(0, "game", "game_cleared")
	tasks = []
	globals = {}
	states = {}
	actives = {}
	event_queue = []
	loading_game = false

func _ready():
	compiler = preload("res://globals/esc_compile.gd").new()
	level = preload("res://globals/vm_level.gd").new()
	level.set_vm(self)

	add_user_signal("global_changed", ["name"])
	add_user_signal("game_paused", ["paused"])

	set_process(true)


