extends TextureButton

func toggle_evidence():
	if get_node("../VBoxContainer").get_children().size() > 0:
		get_node("../../").switch_evidence_to_portrait()

func _ready():
	set_fixed_process(true)
	self.connect("pressed", self, "toggle_evidence")
	get_node("../../").switch_evidence_to_portrait()
