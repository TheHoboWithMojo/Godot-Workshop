# Holds advanced printing functions
extends Node
func throw_warning(warning: String, caller: Node) -> void:
	push_warning(define_error(warning, caller))


func throw_warning_if(condition: bool, warning: String, caller: Node) -> bool:
	if condition == false:
		return false
	throw_warning(warning, caller)
	return true


func throw_error(error: String, caller: Node) -> void:
	push_error(define_error(error, caller))


func throw_error_if(condition: bool, warning: String, caller: Node) -> bool:
	if condition == false:
		return false
	throw_error(warning, caller)
	return true


func define_error(error: String, caller: Node) -> String:
	return ("[%s] '%s': %s" % [Global.get_class_of(caller), caller.name, error])


func debug(message: String, caller: Node, function_name: String, callable_argument_dict: Dictionary[Callable, Array] = {}) -> void:
	if caller.debugging:
		message = " " + message if message else ""
		var class_nomen: String = Global.get_class_of(caller)
		var caller_nomen: String = caller.name
		caller_nomen = " " + caller_nomen if caller_nomen and not caller_nomen == class_nomen else ""
		class_nomen = "[" + class_nomen + "]"
		print("%s%s:%s (%s)" % [class_nomen, caller_nomen, message, function_name])
		for callable: Callable in callable_argument_dict:
			callable.callv(callable_argument_dict[callable])


func debug_if(condition: bool, message: String, caller: Node, function_name: String, callable_argument_dict: Dictionary[Callable, Array] = {}) -> bool:
	if condition == false or not caller.debugging:
		return false
	debug(message, caller, function_name, callable_argument_dict)
	return true


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
		throw_warning("Cannot be called if track frames isn't on.", self)
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
