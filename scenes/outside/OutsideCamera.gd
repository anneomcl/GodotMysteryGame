var leftInvisWallPosition
var rightInvisWallPosition
var offset = 600

func _fixed_process(delta):
	var x_pos = get_node("../").get_pos().x
	if (x_pos < leftInvisWallPosition.x + offset):
		set_global_pos(Vector2(leftInvisWallPosition.x + offset, get_global_pos().y))
	elif (x_pos > rightInvisWallPosition.x - offset):
		set_global_pos(Vector2(rightInvisWallPosition.x - offset, get_global_pos().y))
	else:
		set_pos(Vector2(0, 0))

func _ready():
	leftInvisWallPosition = get_node("../../LeftInvisWall").get_pos()
	rightInvisWallPosition = get_node("../../RightInvisWall").get_pos()
	set_fixed_process(true)