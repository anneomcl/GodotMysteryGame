var game

func _ready():
	game = get_tree().get_root().get_node("game")
	game.execute_cutscene("res://scenes/test/ArchieOfficeIntroCutscene.esc")