extends Node

@export var track_loops: bool = false
var loop_data: Dictionary = {}
var instance_lookup: Dictionary = {}

func _ready() -> void:
	Console.add_command("loopy", print_loops, [], 0, "get overview of loops")
	Console.add_command("data", print_game_data, [], 0, "prints game data")

func _process(delta: float) -> void:
	if not loop_data.is_empty():
		process_tracking(delta)

func _get_node_key(caller: Node) -> String:
	return "%s<%s>%d" % [caller.name, Global.get_class_of(caller), caller.get_instance_id()]

func doc_loop_start(caller: Node, function_name: String, instance_id: int) -> void:
	var key: String = _get_node_key(caller)

	if not loop_data.has(key):
		loop_data[key] = {}

	if not loop_data[key].has(function_name):
		loop_data[key][function_name] = { "instances": {} }

	loop_data[key][function_name]["instances"][instance_id] = { "time": 0.0 }

	instance_lookup[instance_id] = {
		"node_key": key,
		"function_name": function_name,
	}

func doc_loop_end(instance_id: int) -> void:
	if not instance_lookup.has(instance_id):
		return

	var key: String = instance_lookup[instance_id]["node_key"]
	var fn: String = instance_lookup[instance_id]["function_name"]

	if loop_data.has(key) and loop_data[key].has(fn):
		loop_data[key][fn]["instances"].erase(instance_id)
		if loop_data[key][fn]["instances"].is_empty():
			loop_data[key].erase(fn)
		if loop_data[key].is_empty():
			loop_data.erase(key)

	instance_lookup.erase(instance_id)

func process_tracking(delta: float) -> void:
	for key: String in loop_data:
		for fn: String in loop_data[key]:
			for id: int in loop_data[key][fn]["instances"]:
				loop_data[key][fn]["instances"][id]["time"] += delta

func print_loops() -> void:
	for key: String in loop_data:
		print("Node:", key)
		for fn: String in loop_data[key]:
			var instances: Dictionary = loop_data[key][fn]["instances"]
			print("  Function '%s' has %d instances:" % [fn, instances.size()])
			var i: int = 1
			for id: int in instances:
				var time: float = instances[id]["time"]
				print("    - Instance %d: time = %.2f s" % [i, time])
				i += 1


func define_error(error: String, caller: Node) -> String:
	return ("[%s] '%s': %s" % [Global.get_class_of(caller), caller.name, error])



func debug(message: String, caller: Node, function_name: String, callable_argument_dict: Dictionary[Callable, Array] = {}) -> void:
	if caller.debugging:
		var class_nomen: String = "" # class override functionality
		if message.begins_with("["):
			for i: int in range(1, message.length()):
				if message[i] == "]":
					break
				class_nomen += message[i]
			message = message.replace("[" + class_nomen + "] ", "")
		message = " " + message if message else ""
		class_nomen = Global.get_class_of(caller) if not class_nomen else class_nomen
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
		push_warning("[Debug] Cannot be called if track frames isn't on. (frame_print())")
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
