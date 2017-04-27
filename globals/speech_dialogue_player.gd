func start(params, level, is_choice):
	var type
	if params.size() < 2 || !has_resource(params[1]):
		type = "default"
	else:
		type = params[1]

	type = type + Globals.get("platform/dialog_type_suffix")

	var inst = get_resource(type).instance()
	get_node("/root/game").hud_layer.add_child(inst)
	get_node("/root/game").add_hud(inst)

	inst.call_deferred("start", params, level, is_choice)

func _ready():
	add_to_group("dialog_dialog")
