class_name ObjectManager extends Node

enum OBJECTS {UNASSIGNED, VIT_MACHINE}
enum PROPERTIES {REFERENCE, SIGNALS, RETRIEVABLE_NAME}
enum SIGNALS {EVENT_STARTED, EVENT_ENDED}
enum DELAY_MODES {LEVEL_LOADED, REFERENCE_ADDED}

signal object_loaded(loaded_object_node: Node, loaded_object_enum: OBJECTS)
signal object_unloaded(unloaded_object_node: Node, unloaded_object_enum: OBJECTS)
signal object_derefenced(dereferenced_object_enum: OBJECTS)
signal object_referenced(referenced_object_node: Node, referenced_object_enum: OBJECTS)

@export var debugging: bool = false

var object_dict: Dictionary[OBJECTS, Dictionary] = {
	OBJECTS.VIT_MACHINE: {
		PROPERTIES.REFERENCE: null,
		PROPERTIES.SIGNALS: [SIGNALS.EVENT_STARTED, SIGNALS.EVENT_ENDED],
		PROPERTIES.RETRIEVABLE_NAME: "VitMachine",
	},
}

func _ready() -> void:
	object_loaded.connect(_on_object_loaded)
	object_unloaded.connect(_on_object_unloaded)


func _on_object_loaded(loaded_object: Node) -> void:
	assert(loaded_object.has_method("get_object_enum"), "Object %s must have a get_object_enum function to be managed by the object manager" % [loaded_object.name])
	var object_enum: OBJECTS = loaded_object.get_object_enum()
	update_reference(loaded_object, object_enum)



func _on_object_unloaded(object_enum: OBJECTS) -> void:
	remove_reference(object_enum)



func remove_reference(object_enum: OBJECTS) -> void:
	if object_enum == OBJECTS.UNASSIGNED:
		push_error(Debug.define_error("Tried to remove the reference of an unassigned object", self))
		return
	object_dict[object_enum][PROPERTIES.REFERENCE] = null
	var object_name: String = object_dict[object_enum][PROPERTIES.RETRIEVABLE_NAME]
	Debug.debug("Object %s ref successfully removed" % [object_name], self, "remove_reference")
	object_derefenced.emit(object_enum)


func update_reference(object_node: Node, object_enum: OBJECTS) -> bool:
	if object_dict[object_enum][PROPERTIES.REFERENCE] == null:
		object_dict[object_enum][PROPERTIES.REFERENCE] = object_node
		object_dict[object_enum][PROPERTIES.RETRIEVABLE_NAME] = object_node.name
		object_referenced.emit(object_node, object_enum)
		Debug.debug("Object %s's ref successfully updated" % [object_node.name], self, "update_reference")
		return true
	return false


func try_retrieve_object(object_enum: OBJECTS, delay_mode: DELAY_MODES = DELAY_MODES.REFERENCE_ADDED, tries_per_error: int = 5) -> Node:
	var object_name: String = object_dict[object_enum][PROPERTIES.RETRIEVABLE_NAME]
	var tries: int = 0
	while not is_reference_active(object_enum):
		tries += 1
		if tries % tries_per_error == 0:
			push_error(Debug.define_error("Has tried %s times to retrieve the object '%s'" % [tries, object_name], self))
		match(delay_mode):
			DELAY_MODES.REFERENCE_ADDED:
				await object_referenced
			DELAY_MODES.LEVEL_LOADED:
				await Global.level_manager.new_level_loaded
	return object_dict[object_enum][PROPERTIES.REFERENCE]


func object_method_complete(volatile_object_enum: OBJECTS, boolean_completion_method: String, delay_mode: DELAY_MODES = DELAY_MODES.REFERENCE_ADDED, check_delay: float = 0.1, error_timer_duration: float = 10.0) -> void:
	var start_time: float = Time.get_ticks_msec()
	var object_name: String = object_dict[volatile_object_enum][PROPERTIES.RETRIEVABLE_NAME]
	while true:
		var volatile_object: Node = await try_retrieve_object(volatile_object_enum, delay_mode)
		assert(volatile_object.has_method(boolean_completion_method), Debug.define_error("%s does not have the input boolean completion method %s" % [volatile_object.name, boolean_completion_method], self))
		var time_passed_secs: float = (Time.get_ticks_msec() - start_time)/1000
		var times_warned: int = 0
		while volatile_object and not volatile_object.call(boolean_completion_method):
			await Global.delay(self, check_delay)
			time_passed_secs += check_delay
			if time_passed_secs > error_timer_duration * (times_warned + 1):
				times_warned += 1
				push_warning("Waiting for object %s's method '%s' to return true for %s minute(s), warning #%s" % [object_name, boolean_completion_method, round(time_passed_secs/60), times_warned], self)
		if volatile_object and volatile_object.call(boolean_completion_method):
			return
		else:
			volatile_object = await try_retrieve_object(volatile_object_enum)
			continue


func is_reference_active(object: OBJECTS) -> bool:
	return object_dict[object][PROPERTIES.REFERENCE] != null


func object_has_signal(object: OBJECTS, _signal: SIGNALS) -> bool:
	return object_dict[object][PROPERTIES.SIGNALS].has(_signal)
