extends "res://globals/interactive.gd"

var speed = 10
var move_direction = Vector2(0, 0)
var target
var area
var player_camera_zoom = Vector2(1.25, 1.25)

var inventory = []

var camera_locked = false
var camera_pos = Vector2(0, 0)

var canMove = true

var invisWallRight

func _ready():
	set_process_input(true)
	set_fixed_process(true)
	vm.game.set_current_player(self)
	area = get_node("area")

	#move this to some camera script
	get_node("Camera2D").set_zoom(player_camera_zoom)
	
	yield(vm.game, "change_scene_finished")
	set_invis_walls()

func set_invis_walls():
	print(vm.game.current_scene.get_name())
	if vm.game.current_scene != null:
		if get_tree().get_root().has_node(vm.game.current_scene.get_name()):
			if get_tree().get_root().get_node(vm.game.current_scene.get_name()).has_node("InvisibleWallRight"):
				invisWallRight = int(get_tree().get_root().get_node(vm.game.current_scene.get_name()).get_node("InvisibleWallRight").get_pos().x)


func _fixed_process(delta):
	if(vm.can_interact()):
		move_player()
	if(camera_locked):
		get_node("Camera2D").set_global_pos(camera_pos)

	var x_pos = get_pos().x
	if (invisWallRight != null and x_pos >= invisWallRight):
		get_node("Camera2D").set_global_pos(Vector2(invisWallRight, get_node("Camera2D").get_global_pos().y))

func lock_camera(isLocked):
	if isLocked:
		camera_pos = get_node("Camera2D").get_global_pos()
	else:
		get_node("Camera2D").set_pos(Vector2(0, 0))
	camera_locked = isLocked

func _input(event):
	if(vm.can_interact() and event.is_action_pressed("use")):
		var bodies = area.get_overlapping_bodies()
		for body in bodies:
			if body == self:
				continue
			var parent = body.get_parent()
			if parent extends preload("res://globals/interactive.gd") && parent.get_active():
				parent.interact(null)
				break

func move_player():
	move_direction = Vector2(0,0)
	if(Input.is_action_pressed("walk_left")):
		move_direction += Vector2(-1, 0)
	if(Input.is_action_pressed("walk_right")):
		move_direction += Vector2(1, 0)
	if(Input.is_action_pressed("walk_up")):
		move_direction += Vector2(0, -1)
	if(Input.is_action_pressed("walk_down")):
		move_direction += Vector2(0, 1)
	if is_colliding():
        var normal = get_collision_normal()
        move_direction = normal.slide( move_direction )
	move(move_direction.normalized() * speed)

func _on_Area2D_body_enter(body, obj):
	printt("body enter ", body, obj, obj == self)
	if(body == self and obj.get_active()):
		target = obj
	
func _on_Area2D_body_exit(body, obj):
	if(body.get_parent().get_name() == "Player"):
		target = null
