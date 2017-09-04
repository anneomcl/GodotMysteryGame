var game

func _ready():
	game = get_tree().get_root().get_node("game")
	if !game.vm.globals.has("intro"):
		game.vm.set_global_gd("intro", true, false)
	#game.execute_cutscene("res://scenes/test/ArchieOfficeIntroCutscene.esc")