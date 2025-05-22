#@icon("res://assets/Icons/16x16/door.png")
#@export var send_from: Node2D
#@export var send_to: Levels.LEVELS
#@export var spawn_point: SpawnPoint
#@export var require_mouse: bool = true
#@export var require_player: bool = true
#@onready var spawn_at: Vector2
#@onready var _send_to: String = Levels.get_level_path(send_to)
#@onready var processing: bool = true # doesn't run until mouse or player touches it once
#
#func _ready() -> void:
#
	#super._ready()
#
#
#
#func _process(_delta: float) -> void:
	#load_zone()
#
#
#func load_zone() -> void:
	#if not processing:
		#if Global.is_fast_travel_enabled():
			#processing = true
			#if require_mouse and require_player:
				#while Global.player_touching_node == self and Global.mouse_touching_node == self:
					##print("conditions met")
					#if Input.is_action_just_pressed("interact"):
						##print("interacted")
						#Global.level_manager.change_level(send_from, _send_to)
					#await get_tree().process_frame
			#elif require_mouse:
				#while Global.mouse_touching_node == self:
					#if Input.is_action_just_pressed("interact"):
						#Global.level_manager.change_level(send_from, _send_to)
					#await get_tree().process_frame
			#elif require_player:
				#while Global.player_touching_node == self:
					#if Input.is_action_just_pressed("interact"):
						#Global.level_manager.change_level(send_from, _send_to)
					#await get_tree().process_frame
			#processing = false
