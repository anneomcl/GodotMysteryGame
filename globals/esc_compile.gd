const val_localized = 0
const val_local = 1
const val_global = 2

const event_allow_param_names = false

var is_comment_block = false

var commands = {
	"set_global": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"set_value": { "min_args": 3, "lvalues": 1 },
	"set_random_value": { "min_args": 3, "types": [TYPE_STRING, TYPE_INT, TYPE_INT] },
	"debug": { "min_args": 1 },
	"anim": { "min_args": 2 },
	"set_state": { "min_args": 2 },
	"say": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING] },
	"?": { "alias": "dialog"},
	"dialog": { "no_eval": true },
	"cut_scene": { "min_args": 2 },
	">": { "alias": "branch"},
	"branch": { "no_eval": true },
	"<": { "alias": "branch_else" },
	"branch_else": { "no_eval": true },
	"set_active": { "min_args": 2, "types": [TYPE_STRING, TYPE_BOOL] },
	"stop": {},
	"repeat": {},
	"wait": { "min_args": 1, "types": [TYPE_REAL] },
	"teleport": { "min_args": 2 },
	"teleport_pos": { "min_args": 3 },
	"walk_block": { "min_args": 2 },
	"walk": { "min_args": 2 },
	"camera_to_player": { "min_args": 1 },
	"change_scene": { "min_args": 1, "types": [TYPE_STRING] },
	"spawn": { "min_args": 3, "types": [TYPE_STRING, TYPE_INT, TYPE_INT] },
	"%": { "alias": "label", "min_args": 1},
	"jump": { "min_args": 2, "types": [TYPE_BOOL, TYPE_INT] },
	"call_action": { "min_args": 1 },
	"stop_action": { "min_args": 1 },
	"stack_action": { "min_args": 1 },
	"align_character": { "min_args": 2 },
	"animation": {"min_args": 4, "types": [TYPE_STRING, TYPE_BOOL, TYPE_BOOL, TYPE_BOOL] },
	"change_waysystem": { "min_args": 2 },
	"custom": { "min_args": 2 },
	"set_bg_music": { "min_args": 4 },
	"set_volume": { "min_args": 3 },
	"play_sound": { "min_args": 5, "types": [TYPE_STRING, TYPE_INT, TYPE_INT, TYPE_BOOL, TYPE_BOOL] },
	"stop_sound": { "min_args": 1 },
	"award_achievement": { "min_args": 1 },
	"emo_inc": { "min_args": 3, "types": [TYPE_STRING, TYPE_STRING, TYPE_INT] },
	"add_interest_point": { "min_args": 3, "types": [TYPE_STRING, TYPE_STRING, TYPE_INT] },
	"set_param": { "min_args": 3, "types": [TYPE_STRING, TYPE_STRING] },
	"change_type": { "min_args": 3, "types": [TYPE_STRING, TYPE_STRING, TYPE_STRING] },
	"move_to_range": { "min_args": 6, "types": [TYPE_STRING, TYPE_STRING, TYPE_REAL, TYPE_REAL, TYPE_REAL, TYPE_REAL] },
	"spawn_attack": { "min_args": 2, "types": [TYPE_STRING, TYPE_STRING] },
	"attack": { "min_args": 3, "types": [TYPE_STRING, TYPE_STRING, TYPE_REAL] },
	"despawn": { "min_args": 1, "types": [TYPE_STRING] },
	"face": { "min_args": 1, "types": [TYPE_STRING] },
	"harvest": { "min_args": 1, "types": [TYPE_STRING] },
	"accuse": { "min_args": 1, "types": [TYPE_STRING] },
}

var str_index = {}

func check_command(cmd, state, errors):
	if !(cmd.name in commands):
		errors.push_back("line "+str(state.line_count)+": command "+cmd.name+" not valid.")
		return false

	var cmd_data = commands[cmd.name]
	if typeof(cmd_data) == TYPE_BOOL:
		return true

	if "alias" in cmd_data:
		cmd.name = cmd_data.alias

	if "min_args" in cmd_data:
		if cmd.params.size() < cmd_data.min_args:
			var params = ""
			for p in cmd.params:
				params = params + ", " + str(p)
			errors.push_back("line "+str(state.line_count)+": command "+cmd.name+" takes "+str(cmd_data.min_args)+" parameters ("+str(cmd.params.size())+" were given): "+params)
			return false

	var ret = true
	if "types" in cmd_data:
		var i = 0
		for t in cmd_data.types:
			if i >= cmd.params.size():
				break
			if t == TYPE_BOOL:
				if cmd.params[i] == "true":
					cmd.params[i] = true
				elif cmd.params[i] == "false":
					cmd.params[i] = false
				else:
					errors.push_back("line "+str(state.line_count)+": Invalid parameter "+str(i)+" for command "+cmd.name+". Must be 'true' or 'false'.")
					ret = false
			if t == TYPE_INT:
				#printt("converting to int ", cmd.params[i])
				cmd.params[i] = int(cmd.params[i])
			if t == TYPE_REAL:
				cmd.params[i] = float(cmd.params[i])
			i+=1

	return ret

func read_line(state):
	while true:
		if _eof_reached(state.file):
			state.line = null
			return
		else:
			state.line = _get_line(state.file)
			state.line_count += 1
		if !is_comment(state.line):
			return

func is_comment(line):
	if line.length() >= 2 and line[0] == "/" and line[1] == "*":
		is_comment_block = true
		return true
	if line.length() >= 2 and line[0] == "*" and line[1] == "/":
		is_comment_block = false
		return true
	if is_comment_block:
		return true

	for i in range(0, line.length()):
		var char = line[i]
		if char == "#":
			return true
		if char != " " && char != "\t":
			return false
	return true

func get_indent(line):
	for i in range(0, line.length()):
		if line[i] != "\t": #&& line[i] != " "
			return i

func is_event(line):
	var trimmed = trim(line)
	if trimmed.find(":") == 0:
		var ev_line = trimmed.substr(1, trimmed.length()-1)
		var id = ""
		var name = ""
		var sp = ev_line.find(" ")
		if sp >= 0 && event_allow_param_names:
			id = ev_line.substr(0, sp)
			name = ev_line.substr(sp+1, ev_line.length() - sp)
		else:
			id = ev_line
		return { "id": id, "name": name }
	return false

func is_flags(tk):
	var trimmed = trim(tk)
	if trimmed.find("[") == 0 && trimmed.find("]") == trimmed.length()-1:
		return true
	return false

func add_level(state, level, errors):
	read_line(state)
	while typeof(state.line) != typeof(null):
		if typeof(is_event(state.line)) != typeof(false):
			return
		var ind_level = get_indent(state.line)
		if ind_level < state.indent:
			return
		if ind_level > state.indent:
			errors.push_back("line "+str(state.line_count)+": invalid indentation for group")
			read_line(state)
			continue

		read_cmd(state, level, errors)

func add_dialog(state, level, errors):
	read_line(state)
	while typeof(state.line) != typeof(null):
		if typeof(is_event(state.line)) != typeof(false):
			return
		var ind_level = get_indent(state.line)
		if ind_level < state.indent:
			return
		if ind_level > state.indent:
			errors.push_back("line "+str(state.line_count)+": invalid indentation for dialog")
			read_line(state)
			continue
		var read = read_dialog_option(state, level, errors)

func get_token(line, p_from, line_count, errors):
	while p_from < line.length():
		if line[p_from] == " " || line[p_from] == "\t":
			p_from += 1
		else:
			break
	if p_from >= line.length():
		return -1
	var tk_end
	if line[p_from] == "[":
		tk_end = line.find("]", p_from)
		if tk_end == -1:
			errors.push_back("line "+str(line_count)+": unterminated flags")
		tk_end += 1
	elif line[p_from] == "\"":
		tk_end = line.find("\"", p_from+1)
		if tk_end == -1:
			errors.push_back("line "+str(line_count)+": unterminated quotes, line '"+line+"'")
		else:
			tk_end += 1
	else:
		tk_end = p_from
		while tk_end < line.length():
			if line[tk_end] == ":":
				var ntk = get_token(line, tk_end+1, line_count, errors)
				tk_end = ntk
				break
			if line[tk_end] == " " || line[tk_end] == "\t":
				break
			tk_end += 1
	return tk_end

func trim(p_str):
	if p_str.length() == 0:
		return p_str
	while p_str.length() && (p_str[0] == " " || p_str[0] == "\t"):
		p_str = p_str.substr(1, p_str.length()-1)
	while p_str.length() && p_str[p_str.length()-1] == " " || p_str[p_str.length()-1] == "\t":
		p_str = p_str.substr(0, p_str.length()-1)
	if p_str[0] == "\"":
		p_str = p_str.substr(1, p_str.length()-1)
	if p_str.length() == 0:
		return p_str
	if p_str[p_str.length()-1] == "\"":
		p_str = p_str.substr(0, p_str.length()-1)
	return p_str

var num_check

func _is_numeric(val):
	if num_check == null:
		num_check = RegEx.new()
		num_check.compile("^[0123456789\\-.]*$")
	return num_check.find(val) != -1

func parse_flags(p_flags, if_true, if_false, if_inv, if_not_inv, values):
	var from = 1
	var inv_match = RegEx.new()
	inv_match.compile("^!?inv-(.*)$")
	var opr_check = RegEx.new()
	opr_check.compile("([=<>()]+)")
	var opr_match = RegEx.new()
	opr_match.compile("([!=<>()]+)")
	while true:
		var next = p_flags.find(",", from)
		var flag
		if next == -1:
			flag = p_flags.substr(from, (p_flags.length()-1) - from)
		else:
			flag = p_flags.substr(from, next - from)
		flag = trim(flag)

		if opr_check.find(flag) != -1:
			opr_match.find(flag)
			var opr = opr_match.get_captures()[0]
			var pos = flag.find(opr)
			var name = flag.substr(0, pos)
			var val = trim(flag.substr(name.length() + opr.length(), flag.length()))

			name = trim(name)
			if _is_numeric(name):
				name = float(name)
			else:
				name = param_parse(name)

			if _is_numeric(val):
				val = float(val)
			else:
				val = param_parse(trim(val))
			values.push_back([name, opr, val])
		else:
			if flag[0] == "!":
				flag = flag.substr(1, flag.length()-1)
				if_false.push_back(param_parse(flag))
			else:
				if_true.push_back(param_parse(flag))

		if next == -1:
			return
		from = next+1

func read_dialog_option(state, level, errors):
	var tk_end = get_token(state.line, 0, state.line_count, errors)
	var tk = trim(state.line.substr(0, tk_end))
	if tk != "*" && tk != "-":
		errors.append("line "+str(state.line_count)+": Invalid dialog option")
		read_line(state)
		return false
	tk_end += 1
	var q_end = state.line.find("[", tk_end)
	var q_flags = null
	#printt("flags before", q_flags)
	if q_end == -1:
		q_end = state.line.length()
	else:
		var f_end = state.line.find("]", q_end)
		if f_end == -1:
			errors.append("line "+str(state.line_count)+": unterminated flags")
		else:
			f_end += 1
			q_flags = state.line.substr(q_end, f_end - q_end)
	var question = trim(state.line.substr(tk_end, q_end - tk_end))
	var cmd = { "name": "*", "params": [question, []] }

	if q_flags:
		#printt("parsing flags ", q_flags, state.line)
		var if_true = []
		var if_false = []
		var if_inv = []
		var if_not_inv = []
		var values = []
		parse_flags(q_flags, if_true, if_false, if_inv, if_not_inv, values)
		if if_true.size():
			cmd.if_true = if_true
		if if_false.size():
			cmd.if_false = if_false
		if if_inv.size():
			cmd.if_inv = if_inv
		if if_not_inv.size():
			cmd.if_not_inv = if_inv
		if values.size():
			cmd.cond_values = values

	state.indent += 1
	add_level(state, cmd.params[1], errors)
	state.indent -= 1

	level.push_back(cmd)

func read_cmd(state, level, errors):
	var params = []
	var from = 0
	var tk_end = get_token(state.line, from, state.line_count, errors)
	var if_true = []
	var if_false = []
	var if_inv = []
	var if_not_inv = []
	var if_values = []
	while tk_end != -1:
		var tk = trim(state.line.substr(from, tk_end - from))
		from = tk_end + 1
		if is_flags(tk):
			parse_flags(tk, if_true, if_false, if_inv, if_not_inv, if_values)
		else:
			params.push_back(tk)
		tk_end = get_token(state.line, from, state.line_count, errors)

	if params.size() == 0:
		errors.append("line "+str(state.line_count)+": Invalid command.")
		read_line(state)
		return

	var cmd = {"name": params[0]}

	if params[0] == ">":
		cmd.params = []
		state.indent += 1
		add_level(state, cmd.params, errors)
		state.indent -= 1
	elif params[0] == "<":
		cmd.params = []
		state.indent += 1
		add_level(state, cmd.params, errors)
		state.indent -= 1
	elif params[0] == "?":
		params.remove(0)
		var dialog_params = []
		state.indent += 1
		add_dialog(state, dialog_params, errors)
		cmd.params = params
		cmd.params.insert(0, dialog_params)
		state.indent -= 1
	elif params[0] == "*":
		errors.push_back("line "+str(state.line_count)+": Invalid command: dialog option outside dialog")
		read_line(state)
		return
	else:
		params.remove(0)
		cmd.params = params
		for i in range(params.size()):
			if cmd.name in commands && "lvalues" in commands[cmd.name] && i < commands[cmd.name].lvalues:
				continue
			params[i] = param_parse(params[i])
		read_line(state)

	if if_true.size():
		cmd.if_true = if_true
	if if_false.size():
		cmd.if_false = if_false
	if if_inv.size():
		cmd.if_inv = if_inv
	if if_not_inv.size():
		cmd.if_not_inv = if_not_inv
	if if_values.size():
		cmd.cond_values = if_values

	var valid = check_command(cmd, state, errors)
	if valid:
		level.push_back(cmd)

func param_parse(p_param):
	var ret = p_param
	if typeof(ret) != TYPE_STRING:
		return ret
	if p_param[0] == ".":
		ret = [val_global, p_param]
	elif p_param[0] == "$":
		ret = [val_local, p_param.substr(1, p_param.length()-1)]
	elif p_param.find(":\"") >= 0:
		var parts = p_param.split(":\"")
		ret = [val_localized, parts[0], trim(parts[1])]
	else:
		ret = p_param

	return ret

func read_events(f, ret, errors):

	var state = { "file": f, "line": _get_line(f), "indent": 0, "line_count": 0 }

	while typeof(state.line) != typeof(null):
		if is_comment(state.line):
			read_line(state)
			continue
		var ev = is_event(state.line)
		if typeof(ev) != typeof(false):
			var level = []
			var abort = add_level(state, level, errors)
			ret[ev.id] = { "name": ev.name, "level": level, "id": ev.id }
			if abort:
				return abort

func _get_line(f):
	if typeof(f) == typeof({}):
		if f.line >= f.lines.size():
			return null
		var line = f.lines[f.line]
		f.line += 1
		#printt("reading line ", line)
		return line
	else:
		return f.get_line()

func _eof_reached(f):
	if typeof(f) == typeof({}):
		return f.line >= f.lines.size()
	else:
		return f.eof_reached()


func compile_str(p_str, errors):
	str_index = {}
	var f = { "line": 0, "lines": p_str.split("\n") }

	#printt("esc compile str ", f)

	var ret = { _index = [] }
	read_events(f, ret, errors)

	#printt("returning ", p_fname, ret)
	return ret


func compile(p_fname, errors):
	str_index = {}
	var f = File.new()
	f.open(p_fname, File.READ)
	if !f.is_open():
		print("unable to open ", p_fname)
		return {}

	var ret = { _index = [] }
	read_events(f, ret, errors)

	#printt("returning ", p_fname, ret)
	return ret
