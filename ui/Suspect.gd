extends Control

func _ready():
	var name = get_name()
	var filepath = "res://character/avatars/" + name + "_default.png"
	if File.new().file_exists(filepath):
		get_node("Sprite").set_texture(load(filepath))
		get_node("Sprite/Label").set_text(name)