extends Control

# Start single player game
func start_single_player():
	print_debug("Starting game")
	get_tree().change_scene_to_file("../../levels/0/level_0_main.tscn")

func _on_connect_btn_pressed() -> void:
	NetworkService.connect_client()

func _on_disconnect_btn_pressed():
	NetworkService.disconnect_client()

func _on_host_btn_pressed():
	NetworkService.host_server()
	
func _on_single_player_pressed():
	start_single_player()

func _on_name_text_changed():
	PlayerService.local_player_name = $VBoxContainer/NameInput.text 
