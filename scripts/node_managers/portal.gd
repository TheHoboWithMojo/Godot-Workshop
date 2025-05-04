extends Area2D

@export var send_from: Node2D
@export var send_to: PackedScene
@export var require_mouse: bool = true
@export var require_player: bool = true

func _ready() -> void:
	if require_player:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	
	add_to_group("interactable")
	
	if require_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func load_zone() -> void:
	if require_mouse and require_player:
		while Global.player_touching_node == self and Global.mouse_touching_node == self:
			if Input.is_action_just_pressed("interact"):
				Global.game_manager.level_changed.emit(send_from, send_to)
			await get_tree().process_frame
	elif require_mouse:
		while Global.mouse_touching_node == self:
			if Input.is_action_just_pressed("interact"):
				Global.game_manager.level_changed.emit(send_from, send_to)
			await get_tree().process_frame
	elif require_player:
		while Global.player_touching_node == self:
			if Input.is_action_just_pressed("interact"):
				Global.game_manager.level_changed.emit(send_from, send_to)
			await get_tree().process_frame

# the signals below only connect of their respective bools are on
func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = self
		if not require_mouse or Global.mouse_touching_node == self:
			load_zone()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = null

func _on_mouse_entered() -> void:
	Global.mouse_touching_node = self
	if not require_player or Global.player_touching_node == self:
		load_zone()

func _on_mouse_exited() -> void:
	Global.mouse_touching_node = null
