var vm
var game

var item

var hand

var clue_size
var item_clue_size
var clue_parent
var curr_clue
var analysis_data
var curr_node_original_pos

var inventory

var cur_item = -1
var first_item = 0

var item_slots
var slot_names

var item_cursor

var item_cols = 3
var item_rows = 4

var equipped_current

var events

var dragging = false

signal inventory_closed

var base_path = "res://scenes/test/"

#Entry point for inventory updates
func inv_global_changed(name):
	update_items(vm.globals)
	if is_visible():
		update_pages()

#Checks all globals and populates the inventory
#TO-DO Globals should have -> global list (all), items dict, clues dict
#instead of searching through all (This is kind of done but not really)
func update_items(list):
	for it in list:
		#if it.substr(0, 2) == "c/":
			#it.erase(0, 2)
			#if !game.clues.has(it):
			#	game.clues.push_back(it)
			#	print(game.clues)
			#	continue
		
		if it.substr(0, 2) != "i/":
			continue

		if(!game.items.has(it)):
			game.items.push_back(it)

		var in_inv = vm.get_global(it)
		var instanced = get_node("Menu/Inventory").has_node(it)

		if in_inv && !instanced:
			instance_item(find_item(it))
		elif !in_inv && instanced:
			remove_item(it)
		elif in_inv && instanced:
			remove_item(it)
			instance_item(find_item(it))
		
		if instanced and it == _get_current():
			var item = get_node("Menu/Inventory").get_node(it)
			if item.has_node("title") != null:
				item.get_node("title").show()
			if item.has_node("points"):
				item.get_node("points").show()
	if get_node("Menu/Inventory/i").get_child_count() == 0:
		cur_item = -1

#Updates the item slots for rendering.
func update_pages():
	if cur_item == -1:
		find_first_item()

	var parent = get_node("Menu/Inventory/i")
	for i in range(parent.get_child_count()):
		var c = parent.get_child(i)
		c.show()
		c.set_global_pos(item_slots[slot_names.find(c.get_name())])
		
	if cur_item == -1:
		item_cursor.hide()
	else:
		var s = cur_item - first_item
		item_cursor.show()
		item_cursor.set_global_pos(item_slots[s])

#HELPER FUNCTIONS FOR ITEMS
func find_first_item():
	if get_node("Menu/Inventory/i").get_child_count() > 0:
		cur_item = 0
	else:
		cur_item = -1

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
	if !(name in slot_names):
		slot_names.push_back(name)
	get_node("Menu/Inventory/i").add_child(node)
	node.hide()

func find_item(id):
	if id.substr(0, 2) == "i/":
		id.erase(0, 2)
	else:
		return
	for item in inventory.items:
		if id in item.values():
			return item

func remove_item(path):
	if get_node("Menu/Inventory").has_node(path):
		get_node("Menu/Inventory").get_node(path).free()
		str(path.erase(0, 2))
		var i = slot_names.find(path)
		for j in range(i, slot_names.size()):
			if(j + 1 < slot_names.size()):
				slot_names[j] = slot_names[j + 1]
			else:
				slot_names.remove(slot_names.size() - 1)
				return

func find_slots():
	item_slots = []
	slot_names = []
	var n = get_node("Menu/Inventory/item_slots")
	for i in range(n.get_child_count()):
		var c = n.get_child(i)
		item_slots.push_back(c.get_global_pos())
		
func _get_current():
	var id = null
	if cur_item != -1:
		var node = get_node("Menu/Inventory/i").get_node(slot_names[cur_item])
		id = "i/"+node.get_meta("item").id
	return id


#DEPRECATED: USE FOR ITEMS TO-DO REMOVE THIS IN FAVOR OF "SHOW"
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

#EQUIPPED ITEM
func equip():
	var id = _get_current()
	if id == null:
		return

	var label = get_node("Menu/Inventory/Label")
	var desc = find_item(id).description
	label.set_text(desc)
	if game.equipped == id:
		label.set_text("")
	game.equip(id)

func equip_changed(name):
	if equipped_current != null:
		equipped_current.free()
	if name == null:
		return
	elif name == "":
		equipped_current = null
		return
	elif name.substr(0, 2) == "i/":
		name.erase(0, 2)
	else:
		return
		
	var node = get_node("Menu/Inventory/i/" + name)

	if node == null:
		print("warning: can't find equipped item in inventory ", name)
		return
		
	equipped_current = node.duplicate()
	if node.has_node("points"):
		node.get_node("points").hide()
	add_child(equipped_current)
	equipped_current.show()
	equipped_current.set_global_pos(get_node("Menu/Inventory/hand_pos").get_global_pos())

#CURSOR MOVEMENT
func move_cursor(dir):
	var it_count = get_node("Menu/Inventory/i").get_child_count()
	if dir.y != 0:
		if cur_item != -1:
			cur_item += item_cols * dir.y
			if cur_item < 0:
				cur_item = it_count - 1
			elif cur_item >= it_count:
				cur_item = 0

	elif dir.x != 0:
		if dir.x == -1:
			cur_item += dir.x
			if cur_item < 0:
				cur_item = 0
		if dir.x == 1:
			if cur_item == it_count - 1:
				cur_item = 0
			else:
				cur_item += dir.x

	if cur_item != -1:
		if cur_item < first_item:
			first_item = cur_item
		if cur_item >= first_item + item_slots.size():
			first_item = cur_item - item_slots.size()

#OPEN AND CLOSE MENU WINDOWS
#OPTIONS, MAP, INVENTORY
func close():
	hide()
	game.remove_hud(self)
	emit_signal("inventory_closed")

func open():
	instance_clues()
	show()
	game.add_hud(self)
	update_pages()

	if cur_item != -1 :
		get_node("Menu/Inventory/i").get_node(slot_names[cur_item]).get_node("title").show()
		get_node("Menu/Inventory/i").get_node(slot_names[cur_item]).get_node("points").show()
		
func open_fact_analysis():
	if game.current_scene.get_name() != "Analysis":
		get_node("Menu/Options/menu").save_pressed("tempsave")
		game.change_scene(["res://ui/FactAnalysis.tscn"], vm.level.current_context)
		close()


#INPUT EVENTS
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
			get_node("Menu/Inventory/i").get_node(slot_names[cur_item]).get_node("title").hide()
			get_node("Menu/Inventory/i").get_node(slot_names[cur_item]).get_node("points").hide()
		move_cursor(dir)
		update_pages()

	if cur_item != -1 :
		get_node("Menu/Inventory/i").get_node(slot_names[cur_item]).get_node("title").show()
		get_node("Menu/Inventory/i").get_node(slot_names[cur_item]).get_node("points").show()

	if event.is_action("inventory_toggle"):
		close()

	if event.is_action("equip"):
		equip()

#CLUES
func clue_pressed(clue_id):
	var node = clue_parent.get_node(clue_id)
	curr_clue = node
	curr_node_original_pos = curr_clue.get_pos()
	
	var copy = curr_clue.duplicate()
	reparent(copy, clue_parent, null)
	copy.set_pos(curr_clue.get_pos())
	
	dragging = true

func reparent(child, current_parent, target_parent):
	current_parent.remove_child(child)
	if target_parent == null:
		add_child(child)
	else:
		target_parent.add_child(child)

func clue_released(clue_id):
	dragging = false
	remove_child(get_node(clue_id))
	curr_clue.set_pos(curr_node_original_pos)
	curr_clue = null
	
func is_item_clue(clue_id):
	for item in inventory.items:
		if clue_id == item.id:
			return true
	return false

func find_item_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	for item in inventory.items:
		if id in item.values():
			return item

func find_clue(id):
	if id.substr(0, 2) == "c/":
		id.erase(0, 2)
	for item in inventory.clues:
		if id in item.values():
			return item

func instance_clues():
	for clue in game.clues:
		if !clue_parent.has_node(clue):
			if is_item_clue(clue):
				instance_clue(clue, null, null, true)
			else:
				instance_clue(clue, null, null, false)
			
func instance_clue(clue_id, parents, children, is_item):
	var node
	if is_item:
		node = get_node("ItemClue").duplicate()
		var item = find_item_clue(clue_id)
		var spr = Sprite.new()
		spr.set_texture(load(item.icon))
		spr.set_pos(node.get_node("ClueButton/spritePosition").get_pos())
		spr.set_scale(spr.get_scale() * 2)
		node.get_node("ClueButton").add_child(spr)
	else:
		node = get_node("Clue").duplicate()
	node.id = clue_id
	node.content = find_clue(clue_id).title
	node.get_node("ClueButton").get_node("Label").set_text(node.content)
	if (analysis_data.fact_relations.has(clue_id)):
		node.get_node("ClueButton").get_node("points").set_text(str(analysis_data.fact_relations[clue_id]["points"]))
	
	if clue_id.substr(0,2) == "c/":
		clue_id.erase(0, 2)
	node.set_name(clue_id)
	
	node.get_node("ClueButton").connect("button_down", self, "clue_pressed", [clue_id])
	node.get_node("ClueButton").connect("button_up", self, "clue_released", [clue_id])
	
	get_node("Menu/Suspects/SuspectControl/ScrollContainerClues/VBoxContainer").add_child(node)

func drag_box():
	var pos = get_global_mouse_pos()
	var clue_size = get_clue_size(curr_clue)
	if Input.is_mouse_button_pressed(BUTTON_LEFT):
		curr_clue.set_global_pos(pos)
		curr_clue.set_pos(curr_clue.get_pos() - clue_size / 4)

func get_clue_size(node):
	var curr_size
	if (node.get_filename() == "res://ui/InventoryClue.tscn"):
		curr_size = item_clue_size
	else:
		curr_size = clue_size
		
	return curr_size

func _fixed_process(delta):
	if (dragging and Input.is_mouse_button_pressed(BUTTON_LEFT)):
			drag_box()

func _ready():
	game = get_node("/root/game")
	vm = get_node("/root/vm")
	set_fixed_process(true)
	
	clue_size = Vector2(get_node("Clue/ClueButton").get_rect().size.x, get_node("Clue/ClueButton").get_rect().size.y)
	item_clue_size =  Vector2(get_node("ItemClue/ClueButton").get_rect().size.x, get_node("ItemClue/ClueButton").get_rect().size.y)
	
	clue_parent = get_node("Menu/Suspects/SuspectControl/ScrollContainerClues/VBoxContainer")
	analysis_data = get_node("AnalysisData")
	instance_clues()
	
	#INVENTORY (stuff that might get deleted)
	item = get_node("Menu/Inventory/item")
	item.hide()
	item_cursor = get_node("Menu/Inventory/item_cursor")
	inventory = preload("res://game/data/inventory.gd")
	vm.connect("global_changed", self, "inv_global_changed")
	game.call_deferred("connect", "object_equipped", self, "equip_changed")
	find_slots()
