extends "res://globals/interactive.gd"

var speed = 10
var move_direction = Vector2(0, 0)
var target
var area
var player_camera_zoom = Vector2(1.5, 1.5)

var inventory = []

var canMove = true
var canInteract = false

func _ready():
	set_process_input(true)
	set_fixed_process(true)
	vm.game.set_current_player(self)
	area = get_node("area")
	get_node("Camera2D").set_zoom(player_camera_zoom)
	get_node("Camera2D").set_v_drag_enabled(false)
	get_node("Camera2D").set_h_drag_enabled(false)
	get_node("Camera2D").set_pos(Vector2(0, 100))

func _fixed_process(delta):
	if(vm.can_interact()):
		move_player()

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
