extends Area2D
@export var send_from: Node2D
@export var send_to: Levels.LEVELS
@export var spawn_point: SpawnPoint
@export var require_mouse: bool = true
@export var require_player: bool = true
@onready var spawn_at: Vector2
@onready var _send_to: String = Levels.get_level_path(send_to)
@onready var processing: bool = true # doesn't run until mouse or player touches it once

func _ready() -> void:
	if require_player:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
		
	self.set_name("PortalTo" + Levels.get_level_name(send_to)) # enforce naming consistency for outside reference
	
	add_to_group("interactable")
	
	if require_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
		
		
func _process(_delta: float) -> void:
	load_zone()


func load_zone() -> void:
	if not processing:
		if Global.is_fast_travel_enabled():
			processing = true
			if require_mouse and require_player:
				while Global.player_touching_node == self and Global.mouse_touching_node == self:
					print("conditions met")
					if Input.is_action_just_pressed("interact"):
						print("interacted")
						Global.game_manager.level_changed.emit(send_from, _send_to)
					await get_tree().process_frame
			elif require_mouse:
				while Global.mouse_touching_node == self:
					if Input.is_action_just_pressed("interact"):
						Global.game_manager.level_changed.emit(send_from, _send_to)
					await get_tree().process_frame
			elif require_player:
				while Global.player_touching_node == self:
					if Input.is_action_just_pressed("interact"):
						Global.game_manager.level_changed.emit(send_from, _send_to)
					await get_tree().process_frame
			processing = false


# the signals below only connect of their respective bools are on
func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = self
		if not require_mouse or Global.mouse_touching_node == self:
			processing = false


func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = null


func _on_mouse_entered() -> void:
	Global.mouse_touching_node = self
	if not require_player or Global.player_touching_node == self:
		processing = false


func _on_mouse_exited() -> void:
	Global.mouse_touching_node = null
