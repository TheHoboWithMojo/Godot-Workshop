extends StaticBody2D
@onready var event_player: EventPlayer = $EventPlayer

func _ready() -> void:
	ready.connect(_on_tree_entered)
	tree_exited.connect(_on_tree_exited)
	event_player.define_custom_trigger_requirement(Player.is_player_moving)


func _on_tree_entered() -> void:
	Global.object_manager.update_reference(self, ObjectManager.OBJECTS.VIT_MACHINE)


func _on_tree_exited() -> void:
	Global.object_manager.remove_reference(ObjectManager.OBJECTS.VIT_MACHINE)


func is_event_playing() -> bool:
	return event_player.is_event_playing()


func is_event_completed() -> bool:
	return event_player.is_event_complete()
