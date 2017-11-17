extends Node
var vm


func _ready():
	vm = get_node("/root/vm")
	
	var forest_zoom = Vector2(1.8, 1.8)
	var forest_offset = Vector2(0, -450)
	get_node("player/Camera2D").set_zoom(forest_zoom)
	get_node("player/Camera2D").set_offset(forest_offset)
	
	pass
