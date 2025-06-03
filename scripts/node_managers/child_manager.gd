extends Node
class_name ChildManager
@export var enforce_node_type: Node
@onready var children: Array[Node] = get_children(true)
@onready var children_dict: Dictionary = {}


func _ready() -> void:
	Debug.enforce(enforce_node_type != null, "Child Managers must be given a node to enforce its class", self)
	var enforced_class: Variant = enforce_node_type.get_class()
	for child: Node in children:
		Debug.enforce(child.get_class() == enforced_class, "All children of a child manager must be of the same class.", self)
	var names: Array[String] = get_children_names()
	var coords: Array[Vector2] = get_children_coordinates()
	for i: int in children.size():
		var nomen: String = names[i]
		children_dict[nomen] = {
			"Position": "Vector2" + str(coords[i]),
			"Node": children[i]
		}


func get_children_names() -> Array[String]:
	var names: Array[String]
	for child: Node in children:
		names.append(child.name)
	return names



func get_children_coordinates() -> Array[Vector2]:
	var coords: Array[Vector2]
	for child: Node in children:
		coords.append(child.global_position)
	return coords


func get_child_overview() -> void:
	print("%s's children summary:" % [name])
	Debug.pretty_print_dict(children_dict)
