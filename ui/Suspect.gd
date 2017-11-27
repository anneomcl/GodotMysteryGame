extends Control

var evidence = []

func load_evidence_data():
	for item in evidence:
		var label = get_node("Label").duplicate()
		get_node("ScrollContainer/VBoxContainer").add_child(label)
		label.set_text(item.relation + str(item.points) + ": " + item.fact)
	evidence = []

func switch_evidence_to_portrait():
	get_node("ScrollContainer").hide()
	get_node("Sprite").show()

func switch_portrait_to_evidence():
	load_evidence_data()
	get_node("ScrollContainer").show()
	get_node("Sprite").hide()

func load_portrait_data():
	var name = get_name()
	var filepath = "res://character/avatars/" + name + "_default.png"
	if File.new().file_exists(filepath):
		get_node("Sprite").set_normal_texture(load(filepath))
		get_node("NameLabel").set_text(name)

func _ready():
	load_portrait_data()
	load_evidence_data()