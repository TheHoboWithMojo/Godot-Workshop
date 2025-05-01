extends Area2D

@export var parent: Node2D # Ref the signal receiver

@export var detect_player: bool = true
@export var detect_mouse: bool = true

func _ready() -> void:
	if detect_player:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	if detect_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = self
		if parent.has_signal("player_entered_area"):
			parent.player_entered_area.emit(self)

func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		Global.mouse_touching_node = null
		if parent.has_signal("player_exited_area"):
			parent.player_exited_area.emit(self)
			
func _on_mouse_entered() -> void:
	Global.mouse_touching_node = self
	if parent.has_signal("mouse_entered_area"):
		parent.mouse_entered_area.emit(self)

func _on_mouse_exited() -> void:
	Global.mouse_touching_node = null
	if parent.has_signal("mouse_exited_area"):
		parent.mouse_exited_area.emit(self)
