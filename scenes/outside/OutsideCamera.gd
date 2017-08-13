
func _fixed_process():
	var x_pos = get_node("../").get_pos().x
	if (x_pos <= 0):
		set_global(0, get_pos().y)
	elif (x_pos >= 1000):
		set_pos(1000, get_pos().y)

func _ready():
	set_fixed_process(true)