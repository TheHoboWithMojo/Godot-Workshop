class_name DebugBuddy extends Resource
@export var debugging: bool
@export var inherit_debugging: bool

func get_configed_debugging(parent: Node) -> bool:
	return parent.debugging if parent and "debugging" in parent and inherit_debugging else debugging
