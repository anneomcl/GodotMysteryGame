extends "res://globals/scene_base.gd"

func _ready():
	get_node("/root/game").call_deferred("start_new_game")

