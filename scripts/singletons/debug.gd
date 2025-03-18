extends Node

# Holds advanced printing functions

func throw_error(self_node: Node, reason: String, input: Variant = null):
	var file_name: String = self_node.get_script().resource_path.get_file()
	var function_name: String = get_stack()[-1].function  # Get the last function in the call stack
	
	if input == null:
		print("Error: in %s, %s(). %s." % [file_name, function_name, reason])
		return
	
	print("Error: in %s, %s(). %s. Input: %s" % [file_name, function_name, reason, input])

# Print functions - output to console
func pretty_print_dict(dictionary: Dictionary) -> void:
	_print_dict_internal(dictionary)

func _print_dict_internal(dictionary: Dictionary, indent: int = 0) -> void:
	var indent_str = "\t".repeat(indent)
	
	for key in dictionary.keys():
		var value = dictionary[key]
		var key_str = str(key)
		
		if value is Dictionary:
			print(indent_str + key_str + ":")
			_print_dict_internal(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				print(indent_str + key_str + ": []")
			else:
				print(indent_str + key_str + ":")
				_print_array_internal(value, indent + 1)
		else:
			print(indent_str + key_str + ": " + format_value(value))

func pretty_print_array(array: Array) -> void:
	_print_array_internal(array)

func _print_array_internal(array: Array, indent: int = 0) -> void:
	var indent_str = "\t".repeat(indent)
	
	if array.size() == 0:
		print(indent_str + "[]")
		return
	
	for i in range(array.size()):
		var value = array[i]
		
		if value is Dictionary:
			print(indent_str + "[" + str(i) + "]:")
			_print_dict_internal(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				print(indent_str + "[" + str(i) + "]: []")
			else:
				print(indent_str + "[" + str(i) + "]:")
				_print_array_internal(value, indent + 1)
		else:
			print(indent_str + "[" + str(i) + "]: " + format_value(value))

# String functions - return formatted strings
func get_dict_as_pretty_string(dictionary: Dictionary) -> String:
	var result: String = ""
	result += _get_dict_as_string(dictionary)
	return result

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
			result += indent_str + key_str + ": " + format_value(value) + "\n"
	
	return result

func get_array_as_pretty_string(array: Array) -> String:
	return _get_array_as_string(array)

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
			result += indent_str + "[" + str(i) + "]: " + format_value(value) + "\n"
	
	return result

func get_dict_depth(dict: Dictionary) -> int:
	if dict.is_empty():
		return 0
		
	var max_depth := 0
	
	for value in dict.values():
		if value is Dictionary:
			# Recursively check the depth of nested dictionaries
			var nested_depth := get_dict_depth(value) + 1
			max_depth = max(max_depth, nested_depth)
	
	return max_depth

func format_value(value) -> String:
	if value is String:
		return "\"" + value + "\""
	elif value is bool:
		return "true" if value else "false"
	elif value == null:
		return "null"
	else:
		return str(value)
