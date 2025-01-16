extends CharacterBody3D

var thirst_component_node := preload("res://entities/components/thirst_component.tscn")
var health_component_node := preload("res://entities/components/health_component.tscn")
var interactor_component_node := preload("res://entities/player/components/interactor_comp.tscn")
var corpse_node := preload("res://entities/player/player_corpse.tscn")

@export var SPEED := 5.0
@export var is_local_player := true :
	set(input):
		is_local_player = input
		if input == true:
			$Camera.enabled = true
			$InteractorComp.monitoring = true
			$InteractorComp.monitorable = true
			$PlayerInventoryComp.inventory_gui_enabled = true
			reset_local_nodes()
			PlayerGui.show()
		else:
			$Camera.enabled = false
			$PlayerInventoryComp.inventory_gui_enabled = false
			$ThirstComponent.queue_free()
			$HealthComponent.queue_free()
			$InteractorComp.queue_free()
	get:
		return is_local_player
@export var state: PlayerState = PlayerState.new()

const mouse_sens := .002
func _input(event):
	if !is_local_player or PlayerGui.has_open_dialog():
		return
	if event.is_action_pressed("mouse_click"):
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sens)
		$Camera.rotate_x(-event.relative.y * mouse_sens)
		#$Camera.rotation.x = clampf($Camera.rotation.x, -deg_to_rad(70), deg_to_rad(70))

func _ready():
	respawn.rpc()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _physics_process(delta):
	if is_local_player:
		if $HealthComponent.is_dead():
			if Input.is_action_just_pressed("respawn"):
				respawn.rpc()
		else:
			# if not dead
			calculate_movement(delta)
		
func reset_local_nodes():
	if !get_node_or_null("ThirstComponent"):
		var thirst_component = thirst_component_node.instance()
		add_child(thirst_component)
		$ThirstComponent.thirst_changed.connect(PlayerGui.on_thirst_changed)
	if !get_node_or_null("HealthComponent"):
		var health_component = health_component_node.instance()
		add_child(health_component)
		$HealthComponent.health_changed.connect(PlayerGui.on_health_changed)
		$HealthComponent.health_depleted.connect(PlayerGui.on_health_depleted)
	if !get_node_or_null("InteractorComp"):
		var interactor_component = interactor_component_node.instance()
		add_child(interactor_component)

# ==================
# Entity System
# ==================
func init(from_dict: Dictionary = {}): 
	if !from_dict.is_empty():
		if from_dict.has("state"):
			state = PlayerState.new(from_dict.state)
		if from_dict.has("speed"):
			SPEED = from_dict.speed
		if from_dict.has("is_local_player"):
			is_local_player = from_dict.is_local_player
func to_dict(): 
	return {
		"is_local_player": is_local_player,
		"speed": SPEED,
		"state": state.to_dict()
	}
		
# ==================
# Death and respawn
# ==================
@rpc("any_peer", "call_local")
func respawn():
	if is_local_player: 
		#var spawnpoint = await EntityService.get_random_spawnpoint()
		#position.x = spawnpoint.position.x
		#position.y = spawnpoint.position.y
		PlayerGui.reset()
		$HealthComponent.reset()
		$ThirstComponent.reset()
		$InteractorComp.monitoring = true
		$PlayerInventoryComp.inventory_gui_enabled = true
		#Logger.debug("Respawning local player and setting position to: " + str(spawnpoint.position))
	else: 
		Logger.debug("Respawning non-local player")
	$Mesh.show()

func spawn_corpse():
	var player_inventory: InventoryData = $PlayerInventoryComp.inventory
	EntityService.spawn_entity.rpc("res://entities/player/player_corpse.tscn", position, {
		"inventory": player_inventory.to_dict(),
		"player_state": state.to_dict()
	})
	player_inventory.clear_inventory()

func _on_health_depleted():
	if is_local_player:
		$InteractorComp.monitoring = false
		$PlayerInventoryComp.inventory_gui_enabled = false
		spawn_corpse()
	else:
		$Mesh.hide()

# ==================
# Position and movement
# ==================
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed = 5
var jump_speed = 2
func calculate_movement(delta):
	#if not multiplayer.connected_to_server:
		#return
	velocity.y += -gravity * delta
	var input = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var movement_dir = transform.basis * Vector3(input.x, 0, input.y)
	velocity.x = movement_dir.x * speed
	velocity.z = movement_dir.z * speed
	
	move_and_slide()
	
	#if Input.is_action_just_pressed("move_shift"):
		#velocity.y = -jump_speed
	if Input.is_action_just_pressed("move_jump"):
		velocity.y = jump_speed
	#if Input.is_action_just_released("move_jump") or Input.is_action_just_released("move_shift"): 
		#velocity.y = 0
	update_position.rpc(position)
	
@rpc("unreliable_ordered", "any_peer")
func update_position(input_position: Vector3):
	position = input_position


func _on_health_changed(old_value, new_value):
	PlayerGui.on_health_changed(old_value, new_value)

func _on_thirst_changed(old_value, new_value):
	PlayerGui.on_thirst_changed(old_value, new_value)
