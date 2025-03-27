extends Area2D

@export var parent: Node2D

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = self
		if parent.has_signal("player_entered_area"):
			parent.player_entered_area.emit()
		
func _on_mouse_entered() -> void:
	Global.cursor_touching_node = self
	if parent.has_signal("mouse_entered_area"):
		parent.mouse_entered_area.emit()

func _on_mouse_exited() -> void:
	Global.cursor_touching_node = null
	if parent.has_signal("mouse_exited_area"):
		parent.mouse_exited_area.emit()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		Global.cursor_touching_node = null
		if parent.has_signal("player_entered_area"):
			parent.player_exited_area.emit()
