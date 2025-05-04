extends Area2D
# this script automatically connect signals. dont do it in the node menu
@export var parent: Node2D # Ref the signal receiver
@export var detect_player: bool = true
@export var detect_mouse: bool = true
@export var multiple_areas: bool = false # returns the specific area as the node, not the parent (good for levels with checkpoints)
@export var emit_area_as_argument: bool = true # sends area as an argument into signals

func _ready() -> void:
	if detect_player:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	if detect_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		if multiple_areas:
			Global.player_touching_node = self
		else:
			Global.player_touching_node = parent
		if parent.has_signal("player_entered_area"):
			if emit_area_as_argument:
				parent.player_entered_area.emit(self)
			else:
				parent.player_entered_area.emit()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = null
		if parent.has_signal("player_exited_area"):
			if emit_area_as_argument:
				parent.player_exited_area.emit(self)
			else:
				parent.player_exited_area.emit()
			
func _on_mouse_entered() -> void:
	if multiple_areas:
		Global.mouse_touching_node = self
	else:
		Global.mouse_touching_node = parent
	if parent.has_signal("mouse_entered_area"):
		if emit_area_as_argument:
			parent.mouse_entered_area.emit(self)
		else:
			parent.mouse_entered_area.emit()

func _on_mouse_exited() -> void:
	Global.mouse_touching_node = null
	if parent.has_signal("mouse_exited_area"):
		if emit_area_as_argument:
			parent.mouse_exited_area.emit(self)
		else:
			parent.mouse_exited_area.emit()
