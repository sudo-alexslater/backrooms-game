extends Area3D

@export
var thirst: ThirstComponent

# Called when the node enters the scene tree for the first time.
func _ready():
	return
	
func _physics_process(_delta):
	if PlayerGui.has_open_dialog():
		return
	if Input.is_action_just_pressed("interact"):
		initiate_interaction()

var interactables_in_range = []
func _interactable_entered_range(other: Area3D):
	interactables_in_range.append(other)
	
func _interactable_left_range(other: Area3D):
	interactables_in_range.erase(other)

var interacting = false
func initiate_interaction():
	if interactables_in_range.is_empty():
		return
	interacting = true
	print("interacting with one of ", str(interactables_in_range))
	var selected_interactable = interactables_in_range[0]
	if selected_interactable:
		var interaction_data = selected_interactable.interact(get_parent())
		if interaction_data.has("effect"):
			apply_interactable_effect(interaction_data)
		interacting = false
		
func apply_interactable_effect(interaction_data: Dictionary):
	if interaction_data.effect == "thirst":
		thirst.drink(interaction_data.effect_value)

func interact(interactor: Node):
	GameLogger.debug(interactor.name + " has interacted with a player")
	return {}
