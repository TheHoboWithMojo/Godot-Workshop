extends Node
class_name ChildManager
@export var enforced_class: ENFORCABLE_CLASSES
@onready var enforced_class_name: String = class_name_pairs[enforced_class] if enforced_class != ENFORCABLE_CLASSES.UNASSIGNED else "ERROR"
var children_dict: Dictionary = {}

enum ENFORCABLE_CLASSES {
	UNASSIGNED,
	CHILD_MANAGER,
	BEINGS,
	QUEST,
	INTERACTABLE,
	CLICK_DETECTOR,
	TOUCH_DETECTOR,
	NAVPOINT,
	WAYPOINT,
	NODE2D,
	NODE,
	AREA_2D,
	STATIC_BODY_2D,
	CAMERA_2D,
	CHARACTER_BODY_2D,
	COLLISION_SHAPE_2D,
}

var class_name_pairs: Dictionary = {
	ENFORCABLE_CLASSES.CHILD_MANAGER: "ChildManager",
	ENFORCABLE_CLASSES.NAVPOINT: "Navpoint",
	ENFORCABLE_CLASSES.WAYPOINT: "Waypoint",
	ENFORCABLE_CLASSES.BEINGS: "Beings",
	ENFORCABLE_CLASSES.QUEST: "Quest",
	ENFORCABLE_CLASSES.INTERACTABLE: "Interactable",
	ENFORCABLE_CLASSES.CLICK_DETECTOR: "ClickDetector",
	ENFORCABLE_CLASSES.TOUCH_DETECTOR: "TouchDetector",
	ENFORCABLE_CLASSES.NODE2D: "Node2D",
	ENFORCABLE_CLASSES.NODE: "Node",
	ENFORCABLE_CLASSES.AREA_2D: "Area2D",
	ENFORCABLE_CLASSES.STATIC_BODY_2D: "StaticBody2D",
}

func _get_class_name(class_enum: ENFORCABLE_CLASSES) -> String:
	return class_name_pairs[class_enum]

func _ready() -> void:
	assert(enforced_class != ENFORCABLE_CLASSES.UNASSIGNED, Debug.define_error("Child Managers must be given a class to enforce", self))
	child_entered_tree.connect(_on_child_entered_tree)
	var children: Array[Node]
	for child: Node in children:
		if not enforce_class(child):
			return
	var names: Array[String] = get_children_names()
	var coords: Array[Vector2] = get_children_coordinates()
	for i: int in children.size():
		var nomen: String = names[i]
		children_dict[nomen] = {
			"Position": "Vector2" + str(coords[i]),
			"Node": children[i]
		}


func _on_child_entered_tree(node: Node) -> void:
	enforce_class(node)


func enforce_class(node: Node) -> bool:
	if not Global.get_class_of(node) == enforced_class_name:
		Debug.throw_error("%s %s is not of the enforced class type %s" % [Global.get_class_of(node), node.name, enforced_class_name], self)
		node.queue_free()
		return false
	return true


func get_children_names() -> Array[String]:
	var names: Array[String]
	for child: Node in get_children():
		names.append(child.name)
	return names


func get_children_coordinates() -> Array[Vector2]:
	var coords: Array[Vector2]
	for child: Node in get_children():
		coords.append(child.global_position)
	return coords


func get_child_overview() -> void:
	print("%s's children summary:" % [name])
	Debug.pretty_print_dict(children_dict)
