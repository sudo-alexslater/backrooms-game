extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var status_label: Label = $Panel/Margin/VBox/Status

func _ready():
	panel.visible = false
	_layout_panel_top_right()
	_set_status("Inventory debug ready (F8)")


func _layout_panel_top_right() -> void:
	# Anchor to viewport top-right; 12px margin from top and right edges.
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.offset_top = 12.0
	panel.offset_right = -12.0
	panel.offset_left = -392.0
	panel.offset_bottom = 220.0

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F8:
		panel.visible = not panel.visible

func _on_dump_state_pressed():
	var local_inventory = _get_local_player_inventory()
	var world_inventory = _get_first_world_inventory()
	var local_slots = 0 if local_inventory == null else local_inventory.slots.size()
	var world_slots = 0 if world_inventory == null else world_inventory.slots.size()
	var mode = "SERVER" if NetworkService.is_authority() else "CLIENT"
	_set_status("mode=%s local_slots=%d world_slots=%d" % [mode, local_slots, world_slots])
	GameLogger.debug("[InvDebug] local slots: " + str([] if local_inventory == null else local_inventory.slots))
	GameLogger.debug("[InvDebug] world slots: " + str([] if world_inventory == null else world_inventory.slots))

func _on_seed_world_pressed():
	var world_inventory = _get_first_world_inventory()
	if world_inventory == null:
		_set_status("No world inventory found under /root/game/Entities")
		return
	InventoryTransferService.request_seed_random_item_local(world_inventory.get_path())
	_set_status("Requested seed random item into world inventory")

func _on_transfer_world_to_local_pressed():
	var world_inventory = _get_first_world_inventory()
	var local_inventory = _get_local_player_inventory()
	if world_inventory == null:
		_set_status("No world inventory found")
		return
	if local_inventory == null:
		_set_status("Local player inventory not found")
		return
	if world_inventory.slots.is_empty():
		_set_status("World inventory empty")
		return
	var slot = world_inventory.slots[0]
	if not slot.has("item_guid"):
		_set_status("First world slot has no item_guid")
		return
	InventoryTransferService.request_transfer_local(world_inventory.get_path(), local_inventory.get_path(), str(slot.item_guid))
	_set_status("Requested transfer for item " + str(slot.item_guid))

func _get_local_player_inventory() -> EntityInventory:
	var local_player_id = multiplayer.get_unique_id()
	var local_player = PlayerService.get_player_node_or_null(local_player_id)
	if local_player == null:
		return null
	if local_player.has_method("get_inventory"):
		var inventory = local_player.get_inventory()
		if inventory is EntityInventory:
			return inventory
	return null

func _get_first_world_inventory() -> EntityInventory:
	var entities = get_node_or_null("/root/game/Entities")
	if entities == null:
		return null
	for child in entities.get_children():
		if child.has_method("get_inventory"):
			var inventory = child.get_inventory()
			if inventory is EntityInventory:
				return inventory
	return null

func _set_status(message: String):
	status_label.text = message

