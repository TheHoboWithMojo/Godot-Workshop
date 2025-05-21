# Holds advanced printing functions
extends Node

# Public Functions:
func throw_error(self_node_or_file_name: Variant, function_name: String, reason: String, input: Variant = null) -> void:
	var file_name: String
	if self_node_or_file_name is Node:
		file_name = self_node_or_file_name.get_script().resource_path.get_file()
	else:
		file_name = self_node_or_file_name

	var caller_script_name: String = get_stack()[-1].source.get_file()
	var caller_function_name: String = get_stack()[-1].function  # Get the last function in the call stack

	if input == null:
		print("Error: when calling %s() (%s). Reason: %s. Caller: %s (%s)." % [function_name, file_name, reason, caller_script_name, caller_function_name])
		return

	print("Error: when calling %s() (%s). Reason: %s. Caller: %s (%s). Input: %s" % [function_name, file_name, reason, caller_script_name, caller_function_name, input])


func pretty_print_dict(dictionary: Dictionary) -> void:
	_pretty_print_dict(dictionary)


func pretty_print_array(array: Array) -> void:
	_pretty_print_array(array)


func print_game_data() -> void:
	pretty_print_dict(Data.game_data)


func get_dict_as_pretty_string(dictionary: Dictionary) -> String:
	var result: String = ""
	result += _get_dict_as_string(dictionary)
	return result


func get_array_as_pretty_string(array: Array) -> String:
	return _get_array_as_string(array)


func frame_print(input: Variant, frame_print_delay: int) -> void:
	if not Global.game_manager.track_frames:
		throw_error(self, "frame_print", "Cannot be called if track frames isn't on.")
		return
	if Global.frames % frame_print_delay == 0:
		print(input)


func get_methods_completion_times(argumentless_methods: Array[Callable] = [], argument_methods: Array[Callable] = [], arguments: Array = []) -> void:
	# Process methods with arguments first
	for i: int in range(argument_methods.size()):
		var time1: int = Time.get_ticks_msec()
		argument_methods[i].callv(arguments[i])
		var time2: int = Time.get_ticks_msec()
		print(argument_methods[i].get_method(), " took ", time2 - time1, " msec to complete.")

	# Process argumentless methods
	for method: Callable in argumentless_methods:
		var time1: int = Time.get_ticks_msec()
		method.call()
		var time2: int = Time.get_ticks_msec()
		print(method.get_method(), " took ", time2 - time1, " msec to complete.")


# Helper Functions:
# Helper Functions:
func _pretty_print_dict(dictionary: Dictionary, indent: int = 0) -> void:
	var indent_str: String = "\t".repeat(indent)

	for key: Variant in dictionary.keys():
		var value: Variant = dictionary[key]
		var key_str: String = str(key)
		if not (value is Dictionary or value is Array):
			print(indent_str + key_str + ": " + _format_value(value))
			continue

		if value is Dictionary:
			print(indent_str + key_str + ":")
			_pretty_print_dict(value, indent + 1)
			continue
		elif value is Array:
			if not value.size() == 0:
				print(indent_str + key_str + ":")
				_pretty_print_array(value, indent + 1)
				continue
			print(indent_str + key_str + ": []")


func _pretty_print_array(array: Array, indent: int = 0) -> void:
	var indent_str: String = "\t".repeat(indent)

	for i: int in range(array.size()):
		var value: Variant = array[i]

		if not (value is Dictionary or value is Array):
			print(indent_str + "[" + str(i) + "]: " + _format_value(value))
			continue

		if value is Dictionary:
			print(indent_str + "[" + str(i) + "]:")
			_pretty_print_dict(value, indent + 1)
			continue
		elif value is Array:
			if not value.size() == 0:
				print(indent_str + "[" + str(i) + "]:")
				_pretty_print_array(value, indent + 1)
				continue
			print(indent_str + "[" + str(i) + "]: []")


func _get_dict_as_string(dictionary: Dictionary, indent: int = 0) -> String:
	var result: String = ""
	var indent_str: String = "    ".repeat(indent)

	for key: String in dictionary.keys():
		var value: Variant = dictionary[key]
		var key_str: String = str(key)

		if not (value is Dictionary or value is Array):
			result += indent_str + key_str + ": " + _format_value(value) + "\n"
			continue

		if value is Dictionary:
			result += indent_str + key_str + ":\n"
			result += _get_dict_as_string(value, indent + 1)
			continue
		elif value is Array:
			if not value.size() == 0:
				result += indent_str + key_str + ":\n"
				result += _get_array_as_string(value, indent + 1)
				continue
			result += indent_str + key_str + ": []\n"

	return result


func _get_array_as_string(array: Array, indent: int = 0) -> String:
	var result: String = ""
	var indent_str: String = "    ".repeat(indent)

	for i: int in range(array.size()):
		var value: Variant = array[i]

		if not (value is Dictionary or value is Array):
			result += indent_str + "[" + str(i) + "]: " + _format_value(value) + "\n"
			continue

		if value is Dictionary:
			result += indent_str + "[" + str(i) + "]:\n"
			result += _get_dict_as_string(value, indent + 1)
			continue
		elif value is Array:
			if not value.size() == 0:
				result += indent_str + "[" + str(i) + "]:\n"
				result += _get_array_as_string(value, indent + 1)
				continue
			result += indent_str + "[" + str(i) + "]: []\n"

	return result


func _format_value(value: Variant) -> String:
	match typeof(value):
		TYPE_STRING:
			return value
		TYPE_BOOL:
			return "true" if value else "false"
		TYPE_NIL:
			return "null"
		_:
			return str(value)
