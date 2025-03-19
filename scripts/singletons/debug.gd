# Holds advanced printing functions
extends Node

# Public Functions:
func throw_error(self_node: Node, function_name: String, reason: String, input: Variant = null):
	
	var file_name: String = self_node.get_script().resource_path.get_file()
	
	var caller_function_name: String = get_stack()[-1].function  # Get the last function in the call stack
	
	var caller_script_name: String = get_stack()[-1].source.get_file()

	
	if input == null:
		print("Error: when calling %s() (%s). Reason: %s. Caller: %s (%s)." % [function_name, file_name, reason, caller_script_name, caller_function_name])
		return
	
	print("Error: when calling %s() (%s. Reason: %s. Caller: %s (%s). Input: %s" % [function_name, file_name, reason, caller_script_name, caller_function_name, input])
	
	
func pretty_print_dict(dictionary: Dictionary) -> void:
	_pretty_print_dict(dictionary) # Recursion handled elsewhere to avoid extra argument

func pretty_print_array(array: Array) -> void:
	_pretty_print_array(array) # Recursion handled elsewhere to avoid extra argument

func get_dict_as_pretty_string(dictionary: Dictionary) -> String:
	var result: String = ""
	result += _get_dict_as_string(dictionary)
	return result

func get_array_as_pretty_string(array: Array) -> String:
	return _get_array_as_string(array)
	
func print_player_perks():
	print("=== All Perks ===")
	for perk_name in Data.game_data["perks"]:
		var perk = Data.game_data["perks"][perk_name]
		print("\nPerk: ", perk_name)
		for property in perk:
			print("  %s: %s" % [property, perk[property]])

func print_player_traits():
	print("=== All Traits ===")
	for trait_name in Data.game_data["traits"]:
		var _trait = Data.game_data["traits"][trait_name]
		print("\nTrait: ", trait_name)
		for property in _trait:
			print("  %s: %s" % [property, _trait[property]])

# Helper Functions:
func _pretty_print_dict(dictionary: Dictionary, indent: int = 0) -> void:
	var indent_str = "\t".repeat(indent)
	
	for key in dictionary.keys():
		var value = dictionary[key]
		var key_str = str(key)
		
		if value is Dictionary:
			print(indent_str + key_str + ":")
			_pretty_print_dict(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				print(indent_str + key_str + ": []")
			else:
				print(indent_str + key_str + ":")
				_pretty_print_array(value, indent + 1)
		else:
			print(indent_str + key_str + ": " + _format_value(value))

func _pretty_print_array(array: Array, indent: int = 0) -> void:
	var indent_str = "\t".repeat(indent)
	
	if array.size() == 0:
		print(indent_str + "[]")
		return
	
	for i in range(array.size()):
		var value = array[i]
		
		if value is Dictionary:
			print(indent_str + "[" + str(i) + "]:")
			_pretty_print_dict(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				print(indent_str + "[" + str(i) + "]: []")
			else:
				print(indent_str + "[" + str(i) + "]:")
				_pretty_print_array(value, indent + 1)
		else:
			print(indent_str + "[" + str(i) + "]: " + _format_value(value))
	
func _get_dict_as_string(dictionary: Dictionary, indent: int = 0) -> String:
	var result = ""
	var indent_str = "    ".repeat(indent)  # Using spaces for better display in UI
	
	for key in dictionary.keys():
		var value = dictionary[key]
		var key_str = str(key)
		
		if value is Dictionary:
			result += indent_str + key_str + ":\n"
			result += _get_dict_as_string(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				result += indent_str + key_str + ": []\n"
			else:
				result += indent_str + key_str + ":\n"
				result += _get_array_as_string(value, indent + 1)
		else:
			result += indent_str + key_str + ": " + _format_value(value) + "\n"
	
	return result

func _get_array_as_string(array: Array, indent: int = 0) -> String:
	var result = ""
	var indent_str = "    ".repeat(indent)  # Using spaces for better display in UI
	
	if array.size() == 0:
		return indent_str + "[]\n"
	
	for i in range(array.size()):
		var value = array[i]
		
		if value is Dictionary:
			result += indent_str + "[" + str(i) + "]:\n"
			result += _get_dict_as_string(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				result += indent_str + "[" + str(i) + "]: []\n"
			else:
				result += indent_str + "[" + str(i) + "]:\n"
				result += _get_array_as_string(value, indent + 1)
		else:
			result += indent_str + "[" + str(i) + "]: " + _format_value(value) + "\n"
	
	return result

func _format_value(value) -> String:
	if value is String:
		return "\"" + value + "\""
	elif value is bool:
		return "true" if value else "false"
	elif value == null:
		return "null"
	else:
		return str(value)
