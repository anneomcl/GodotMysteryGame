extends TextureButton

func toggle_portrait():
	if get_node("../").evidence.size() > 0 or get_node("../ScrollContainer/VBoxContainer").get_children().size() > 0:
		get_node("../").switch_portrait_to_evidence()

func _ready():
	set_fixed_process(true)
	self.connect("pressed", self, "toggle_portrait")
	get_node("../").switch_evidence_to_portrait()
