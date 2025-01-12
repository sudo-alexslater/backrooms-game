extends Area2D
class_name InteractableComponent

signal interacted_with(interactor)
var interactable_parent

func _ready():
	interactable_parent = get_parent()

func interact(interactor: Node):
	interacted_with.emit(interactor)
	interactable_parent.interact(interactor)
	return interactable_parent.get_interaction_details()
