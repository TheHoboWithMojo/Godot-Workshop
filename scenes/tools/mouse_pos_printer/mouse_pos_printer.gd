@tool
extends RichTextLabel

@export var tool_mode: bool = true

func _process(_delta: float) -> void:
	if not tool_mode and Engine.is_editor_hint():
		set_text("")
		return
	var pos: Vector2 = get_global_mouse_position() + Vector2(-18, 8)
	set_global_position(pos)
	set_text(str(get_global_mouse_position()))
