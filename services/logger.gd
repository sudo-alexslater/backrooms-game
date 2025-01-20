extends Node

var multiplayer_prefix: String :
	get:
		if not multiplayer.connected_to_server:
			return "[SP]"
		return "[" + str(multiplayer.get_unique_id()) + "]"
var debug_prefix : String : 
	get:
		return "[?] " + multiplayer_prefix + " "
var error_prefix : String : 
	get:
		return "[!] " + multiplayer_prefix + " "

func debug(input: Variant):
	print(debug_prefix + str(input))
	
func error(input: Variant):
	print(error_prefix + str(input))
