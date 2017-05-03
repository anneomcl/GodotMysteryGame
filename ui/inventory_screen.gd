var vm
var game

var item
var clue

var hand

var inventory

var cur_item = -1
var first_item = 0

var cur_clue = -1
var first_clue = 0

var item_slots
var clue_slots

var item_cursor
var clue_cursor

var item_cols = 2

var equipped_current

var events

signal inventory_closed

var base_path = "res://scenes/test/"

func location_pressed(name):
	close()
	#TO-DO: Fading animation
	game.change_scene([name], vm.level.current_context)

func update_slots(parent, slots, first, current, cursor):
	var slot = 0
	for i in range(parent.get_child_count()):
		var c = parent.get_child(i)
		if i < first || i >= first + slots.size():
			c.hide()
		else:
			c.show()
			c.set_global_pos(slots[slot])
			slot += 1

	if current == -1:
		cursor.hide()
	else:
		var s = current - first
		cursor.show()
		cursor.set_global_pos(slots[s])

func find_first_item():
	if get_node("Menu/Inventory/i").get_child_count() > 0:
		cur_item = 0
		cur_clue = -1
	elif get_node("Menu/Inventory/c").get_child_count() > 0:
		cur_clue = 0
		cur_item = -1

	else:
		cur_item = -1
		cur_clue = -1

func update_pages():
	if cur_item == -1 && cur_clue == -1:
		find_first_item()
	update_slots(get_node("Menu/Inventory/i"), item_slots, first_item, cur_item, item_cursor)
	update_slots(get_node("Menu/Inventory/c"), clue_slots, first_clue, cur_clue, clue_cursor)


func global_changed(name):
	if name.find("i/") != 0 && name.find("c/") != 0:
		return

	update_items()

	if is_visible():
		update_pages()

func instance_item(p_item):
	var node = item.duplicate()
	var name = p_item.id
	var points = ""
	if "icon" in p_item:
		node.get_node("icon").set_texture(load(p_item.icon))
	if "points" in p_item and vm.get_global(name):
		points = str(p_item.points, "% suspicion")
	node.set_name(name)
	node.get_node("title").set_text(name)
	node.get_node("points").set_text(points)
	node.get_node("title").hide()
	node.get_node("points").hide()
	node.set_meta("item", p_item)
	get_node("Menu/Inventory/i").add_child(node)
	node.hide()

func instance_clue(p_clue):
	var node = clue.duplicate()
	node.set_name(p_clue.id)
	node.get_node("title").set_text(p_clue.title)
	node.set_meta("clue", p_clue)
	get_node("c").add_child(node)
	node.hide()

func remove_item(path):
	if has_node(path):
		get_node(path).free()

func check_instances(list, prefix):
	for it in list:
		var gid = prefix + it.id
		var in_inv = vm.get_global(gid)
		var instanced = has_node(gid)

		if in_inv && !instanced:
			if prefix == "i/":
				instance_item(it)
			else:
				instance_clue(it)
		elif !in_inv && instanced:
			remove_item(gid)
		elif in_inv && instanced:
			remove_item(gid)
			if prefix == "i/":
				instance_item(it)
			else:
				instance_clue(it)
		
		if has_node(gid) and gid == _get_current():
			var item = get_node(gid)
			if item.has_node("title") != null:
				item.get_node("title").show()
			if item.has_node("points"):
				item.get_node("points").show()

func update_items():
	check_instances(inventory.items, "i/")
	check_instances(inventory.clues, "c/")

	if get_node("Menu/Inventory/i").get_child_count() == 0:
		cur_item = -1
	if get_node("Menu/Inventory/c").get_child_count() == 0:
		cur_clue = -1

func find_slots():
	item_slots = []
	var n = get_node("Menu/Inventory/item_slots")
	for i in range(n.get_child_count()):
		var c = n.get_child(i)
		item_slots.push_back(c.get_global_pos())

	clue_slots = []
	n = get_node("Menu/Inventory/clue_slots")
	for i in range(n.get_child_count()):
		var c = n.get_child(i)
		clue_slots.push_back(c.get_global_pos())

func input(event):
	if event.is_echo():
		return
	if !event.is_pressed():
		return

	var dir = Vector2()
	if event.is_action("ui_up"):
		dir.y = -1
	elif event.is_action("ui_down"):
		dir.y = 1
	elif event.is_action("ui_left"):
		dir.x = -1
	elif event.is_action("ui_right"):
		dir.x = 1

	if dir != Vector2():
		if cur_item != -1:
			get_node("Menu/Inventory/i").get_child(cur_item).get_node("title").hide()
			get_node("Menu/Inventory/i").get_child(cur_item).get_node("points").hide()
		move_cursor(dir)
		update_pages()

	if cur_item != -1 :
		get_node("Menu/Inventory/i").get_child(cur_item).get_node("title").show()
		get_node("Menu/Inventory/i").get_child(cur_item).get_node("points").show()

	if event.is_action("inventory_toggle"):
		close()

	if event.is_action("equip"):
		equip()

	if event.is_action("combine"):
		combine()

func _get_current():
	var id = null
	if cur_item != -1:
		var node = get_node("Menu/Inventory/i").get_child(cur_item)
		id = "i/"+node.get_meta("item").id
	elif cur_clue != -1:
		var node = get_node("Menu/Inventory/c").get_child(cur_clue)
		if node != null:
			id = "c/"+node.get_meta("clue").id

	return id

func interact():
	var id = _get_current()
	if id == null:
		return

	var ev_name = "use "+id
	if ev_name in events:
		close()
		vm.run_event(events[ev_name], {})
	else:
		print("warning: event use not found for item ", id)

func equip():
	var id = _get_current()
	if id == null:
		return

	game.equip(id)

func combine():
	var current = _get_current()
	if current == null:
		return

	var equipped = game.get_equipped()
	if current == equipped or equipped == null:
		return

	var ev_name = "combine "+current+" "+equipped
	if ev_name in events:
		close()
		vm.run_event(events[ev_name], {})
		return

	ev_name = "combine "+equipped+" "+current
	if ev_name in events:
		close()
		vm.run_event(events[ev_name], {})
		return

	close()
	vm.run_event(events.combine_fallback, {})


func equip_changed(name):
	if equipped_current != null:
		equipped_current.free()

	if name == null:
		return

	var node = get_node(name)

	if node == null:
		print("warning: can't find equipped item in inventory ", name)
		return

	if name == "":
		equipped_current = null
		return
		
	equipped_current = node.duplicate()
	if node.has_node("points"):
		node.get_node("points").hide()
	add_child(equipped_current)
	equipped_current.show()
	equipped_current.set_global_pos(get_node("Menu/Inventory/hand_pos").get_global_pos())

func move_cursor(dir):
	var it_count = get_node("Menu/Inventory/i").get_child_count()
	var clue_count = get_node("Menu/Inventory/c").get_child_count()
	if dir.y != 0:
		if cur_item != -1:
			cur_item += item_cols * dir.y
			if cur_item < 0:
				cur_item = it_count - 1
			elif cur_item >= it_count:
				cur_item = 0
		if cur_clue != -1:
			cur_clue += dir.y
			if cur_clue < 0:
				cur_clue = clue_count - 1
			elif cur_clue >= clue_count:
				cur_clue = 0

	elif dir.x != 0:
		if cur_clue != -1:
			cur_item = first_item
			cur_clue = -1
		elif cur_item != -1:
			if dir.x == -1:
				cur_item += dir.x
				if cur_item < 0:
					cur_item = 0
				if cur_item >= it_count:
					cur_item = it_count - 1
			if dir.x == 1:
				if int(cur_item) % 2 == 1 || cur_item == it_count -1:
					cur_clue = first_clue
					cur_item = -1
				else:
					cur_item += dir.x
					if cur_item < 0:
						cur_item = 0
					if cur_item >= it_count:
						cur_item = it_count - 1

	if cur_item != -1:
		if cur_item < first_item:
			first_item = cur_item
		if cur_item >= first_item + item_slots.size():
			first_item = cur_item - item_slots.size()

	if cur_clue != -1:
		if cur_clue < first_clue:
			first_clue = cur_clue
		if cur_clue >= first_clue + clue_slots.size():
			first_clue = cur_clue - clue_slots.size()

func close():
	hide()
	game.remove_hud(self)
	emit_signal("inventory_closed")

func open():
	show()
	game.add_hud(self)
	update_pages()

	if cur_item != -1 :
		get_node("Menu/Inventory/i").get_child(cur_item).get_node("title").show()
		get_node("Menu/Inventory/i").get_child(cur_item).get_node("points").show()

func _ready():
	game = get_node("/root/game")
	vm = get_node("/root/vm")

	events = vm.compile("res://game/inventory_events.esc")

	item = get_node("Menu/Inventory/item")
	item.hide()
	clue = get_node("Menu/Inventory/clue")
	clue.hide()

	item_cursor = get_node("Menu/Inventory/item_cursor")
	clue_cursor = get_node("Menu/Inventory/clue_cursor")

	inventory = preload("res://game/inventory.gd")

	vm.connect("global_changed", self, "global_changed")
	game.call_deferred("connect", "object_equipped", self, "equip_changed")
	
	get_node("Menu/Map/Waldorf").connect("pressed", self, "location_pressed", [base_path + "TeaRoom.tscn"])
	get_node("Menu/Map/Office").connect("pressed", self, "location_pressed", [base_path + "SquashSquadOffice.tscn"])

	find_slots()
