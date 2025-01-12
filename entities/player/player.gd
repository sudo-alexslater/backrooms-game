extends CharacterBody2D
class_name Player

var thirst_component_node := preload("res://entities/components/thirst_component.tscn")
var health_component_node := preload("res://entities/components/health_component.tscn")
var interactor_component_node := preload("res://entities/player/components/interactor_component.tscn")
var corpse_node := preload("res://entities/player/player_corpse.tscn")

@export var SPEED := 600.0
@export var is_local_player := true :
	set(input):
		is_local_player = input
		if input == true:
			$Camera.enabled = true
			$InteractorComponent.monitoring = true
			$InteractorComponent.monitorable = true
			$PlayerInventoryComponent.inventory_gui_enabled = true
			reset_local_nodes()
			PlayerGui.show()
		else:
			$Camera.enabled = false
			$PlayerInventoryComponent.inventory_gui_enabled = false
			$ThirstComponent.queue_free()
			$HealthComponent.queue_free()
			$InteractorComponent.queue_free()
	get:
		return is_local_player
@export var state: PlayerState = PlayerState.new()

func _ready():
	respawn.rpc()
	
func _physics_process(delta):
	if is_local_player:
		if $HealthComponent.is_dead():
			if Input.is_action_just_pressed("respawn"):
				respawn.rpc()
		else:
			# if not dead
			calculate_movement()
		
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
	if !get_node_or_null("InteractorComponent"):
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
		var spawnpoint = await EntityService.get_random_spawnpoint()
		position.x = spawnpoint.position.x
		position.y = spawnpoint.position.y
		PlayerGui.reset()
		$HealthComponent.reset()
		$ThirstComponent.reset()
		$InteractorComponent.monitoring = true
		$PlayerInventoryComponent.inventory_gui_enabled = true
		Logger.debug("Respawning local player and setting position to: " + str(spawnpoint.position))
	else: 
		Logger.debug("Respawning non-local player")
	$Sprite.show()
	$Sprite.play("idle_front")

func spawn_corpse():
	var player_inventory: InventoryData = $PlayerInventoryComponent.inventory
	EntityService.spawn_entity.rpc("res://entities/player/player_corpse.tscn", position, {
		"inventory": player_inventory.to_dict(),
		"player_state": state.to_dict()
	})
	player_inventory.clear_inventory()

func _on_health_depleted():
	if is_local_player:
		$InteractorComponent.monitoring = false
		$PlayerInventoryComponent.inventory_gui_enabled = false
		spawn_corpse()
	else:
		$Sprite.hide()

# ==================
# Position and movement
# ==================
func calculate_movement():
	if not multiplayer.connected_to_server:
		return
	velocity.x = (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * SPEED
	velocity.y = (Input.get_action_strength("move_down") - Input.get_action_strength("move_up")) * SPEED
	update_position.rpc(position)
	move_and_slide()
	
@rpc("unreliable_ordered", "any_peer")
func update_position(input_position: Vector2):
	position = input_position


func _on_health_changed(old_value, new_value):
	PlayerGui.on_health_changed(old_value, new_value)

func _on_thirst_changed(old_value, new_value):
	PlayerGui.on_thirst_changed(old_value, new_value)
