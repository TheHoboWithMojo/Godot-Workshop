extends Node

# Holds advanced printing functions
func throw_error(self_node: Node, reason: String, input: Variant = null):
		
	var file_name: String = self_node.get_script().resource_path.get_file()
	var function_name: String = get_stack()[-1].function  # Get the last function in the call stack
	if input == null:
		print("Error: in %s, %s(). %s." % [file_name, function_name, reason])
		return
	
	print("Error: in %s, %s(). %s. Input: %s" % [file_name, function_name, reason, input])
	
func print_dict(dictionary: Dictionary, indent: int = 0) -> void:
	if indent == 0:
		print("\n=== Dictionary Contents ===")
	
	var indent_str = "\t".repeat(indent)
	
	for key in dictionary.keys():
		var value = dictionary[key]
		var key_str = str(key)
		
		if value is Dictionary:
			print(indent_str + key_str + ":")
			print_dict(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				print(indent_str + key_str + ": []")
			else:
				print(indent_str + key_str + ":")
				print_array(value, indent + 1)
		else:
			print(indent_str + key_str + ": " + format_value(value))


func print_array(array: Array, indent: int = 0) -> void:
	var indent_str = "\t".repeat(indent)
	
	if array.size() == 0:
		print(indent_str + "[]")
		return
	
	for i in range(array.size()):
		var value = array[i]
		
		if value is Dictionary:
			print(indent_str + "[" + str(i) + "]:")
			print_dict(value, indent + 1)
		elif value is Array:
			if value.size() == 0:
				print(indent_str + "[" + str(i) + "]: []")
			else:
				print(indent_str + "[" + str(i) + "]:")
				print_array(value, indent + 1)
		else:
			print(indent_str + "[" + str(i) + "]: " + format_value(value))


func format_value(value) -> String:
	if value is String:
		return "\"" + value + "\""
	elif value is bool:
		return "true" if value else "false"
	elif value == null:
		return "null"
	else:
		return str(value)
