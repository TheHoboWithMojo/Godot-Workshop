#extends Interactable
#class_name Portal
#@export_group("ESSENTIALS")
#@export var send_from: Node2D
#@export var send_to: Levels.LEVELS
#@export var spawn_point: SpawnPoint
#@export var _click_detector: ClickDetector
#@export var detection_zone: Collider
#
#@onready var _send_to: String = Levels.get_level_path(send_to)
#@onready var processing: bool = false # doesn't run until mouse or player touches it once
#@onready var _entry_detector: TouchDetector = $EntryDetector
#
#
#func _raady() -> void:
	#print("running")
	#assert(send_from and send_to and spawn_point and _click_detector and _entry_detector, "THESE VARIABLES ARE ESSENTIAL")
	#detection_zone.reparent(_entry_detector)
	#self.set_name("PortalTo" + Levels.get_level_name(send_to)) # enforce naming consistency for outside reference
	#super.set_play_mode(PLAY_MODES.PLAY_SCENE)
	#super.set_trigger_mode(TRIGGER_MODES.TRIGGER_ON_CLICK_AND_ENTRY)
	#super.set_scene_path_to_play(_send_to)
	#super.set_click_detector(_click_detector)
	#super.set_entry_detector(_entry_detector)
	##super._ready()
#
#
#func _try_play_scene() -> void: # overrides the _try_play_scene method
	#print("PORTAL IS WORKING")
	#if not processing:
		#processing = true
		#Global.level_manager.change_level(send_from, _send_to)
		#processing = false
