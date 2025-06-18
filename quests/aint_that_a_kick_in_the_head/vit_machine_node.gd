extends StaticBody2D
@onready var event_player: EventPlayer = $EventPlayer
@onready var aint_that_a_kick_in_the_head: AintThatAKickInTheHead = Global.quest_manager.aint_that_a_kick_in_the_head

func _ready() -> void:
	await Global.ready_to_start()
	if aint_that_a_kick_in_the_head.use_the_vit.is_finished():
		event_player.set_enabled(false)
		return
	event_player.event_started.connect(_on_event_started)
	event_player.event_ended.connect(_on_event_ended)


func _on_event_started() -> void:
	aint_that_a_kick_in_the_head.vit_started.emit()


func _on_event_ended() -> void:
	aint_that_a_kick_in_the_head.vit_ended.emit()

	#ready.connect(_on_tree_entered)
	#tree_exited.connect(_on_tree_exited)
	#event_player.define_custom_trigger_requirement(Player.is_player_moving)


#func _on_tree_entered() -> void:
	#Global.object_manager.update_reference(self, ObjectManager.OBJECTS.VIT_MACHINE)
#
#
#func _on_tree_exited() -> void:
	#Global.object_manager.remove_reference(ObjectManager.OBJECTS.VIT_MACHINE)


#func is_event_playing() -> bool:
	#return event_player.is_event_playing()
#
#
#func is_event_finished() -> bool:
	#return event_player.is_event_finishe()
