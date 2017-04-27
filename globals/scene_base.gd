

func _ready():
	get_node("/root/game").call_deferred("set_current_scene", self)
	pass

