extends Control

var evidence = []

func load_evidence_data():
	for item in evidence:
		var label = get_node("Label").duplicate()
		get_node("ScrollContainer/VBoxContainer").add_child(label)
		label.set_text(item.relation + item.points + ": " + item.fact)
	evidence = []

func suspect_pressed():
	if (Input.is_action_pressed("combine")):
		load_evidence_data()
		get_node("ScrollContainer").show()
		get_node("Sprite").hide()

func load_portrait_data():
	var name = get_name()
	var filepath = "res://character/avatars/" + name + "_default.png"
	if File.new().file_exists(filepath):
		get_node("Sprite").set_normal_texture(load(filepath))
		get_node("Sprite/Label").set_text(name)

func _ready():
	get_node("Sprite").connect("button_down", self, "suspect_pressed")
	load_portrait_data()
	load_evidence_data()