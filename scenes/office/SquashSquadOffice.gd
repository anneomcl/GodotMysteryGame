extends Node

var vm

func _ready():
	vm = get_tree().get_root().get_node("vm")
	if vm.get_global("has_keys"):
		get_node("Room").remove_child(get_node("Room/A"))
	
	pass
