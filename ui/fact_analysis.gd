var game
var vm
var menu
var inventory

func back_to_game():
	menu.load_pressed()


func instance_clue():
	var node = get_node("Clue").duplicate()
	node.set_pos(Vector2(350, 150))
	node.get_node("Label").set_text(inventory.clues[0].title)
	get_node("c").add_child(node)

func _ready():
	game = get_node("/root/game")
	vm = get_node("/root/vm")
	inventory = preload("res://game/inventory.gd")
	menu = get_node("/root/game/hud_layer/inventory/Menu/Options/menu")

	get_node("Back").connect("pressed", self, "back_to_game")
	instance_clue()