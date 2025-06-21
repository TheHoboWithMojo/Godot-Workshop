extends Node

@export var debugging: bool = false

enum ITEMS { UNASSIGNED, FIREBALL, ORB}
enum PROPERTIES { SCENE_PATH, TEXTURE_PATH}

var items_dict: Dictionary[ITEMS, Dictionary] = {
	ITEMS.FIREBALL: {
		PROPERTIES.SCENE_PATH: "res://scenes/projectiles/fireball/fireball.tscn",
		PROPERTIES.TEXTURE_PATH: "res://assets/Icons/16x16/bomb.png",
	},
	ITEMS.ORB: {
		PROPERTIES.SCENE_PATH: "res://scenes/projectiles/orb/orb.tscn",
		PROPERTIES.TEXTURE_PATH: "res://assets/Icons/16x16/light_negative.png",
	},
}

func ready() -> void:
	await Global.ready_to_start()
	for file_path: String in items_dict.values():
		assert(FileAccess.file_exists(file_path), "The filepath %s does not exist" % [file_path])


func get_item_node(item: ITEMS) -> Node:
	return load(items_dict[item][PROPERTIES.SCENE_PATH]).instantiate()


func get_item_texture(item: ITEMS) -> Texture2D:
	if item == ITEMS.UNASSIGNED:
		Debug.debug("Tried to retrieve an unassigned item", self, "get_item_texture")
		return
	return load(items_dict[item][PROPERTIES.TEXTURE_PATH])


func get_item_name(item: ITEMS) -> String:
	return Global.enum_to_camelcase(item, ITEMS)
