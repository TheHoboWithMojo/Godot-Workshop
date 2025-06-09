class_name PortalManager extends ChildManager
@export var home_level_node: Level
@onready var home_level_enum: Levels.LEVELS = home_level_node.get_level_enum() if home_level_node else Levels.LEVELS.UNASSIGNED

func get_portal_to(level: Levels.LEVELS) -> Portal:
	var level_name: String = Levels.get_level_name(level)
	var portal: Array = get_children().filter(func(_portal: Portal) -> bool: return _portal.get_send_to_level_enum() == level)
	match(portal.size()):
		0:
			push_error(Debug.define_error("No portals to level %s was found" % [level_name], home_level_node))
			return null
		1:
			Debug.debug("Returning portal to level %s" % [level_name], home_level_node, "get_portal_to_level")
			return portal[0]
		_:
			push_error(Debug.define_error("More than one portal to level %s was found in level %s, returning the first" % [level_name, home_level_node.name], self))
			return portal[0]


func get_portals() -> Array[Portal]:
	var portals: Array[Portal]
	for portal: Portal in get_children():
		portals.append(portal)
	return portals
