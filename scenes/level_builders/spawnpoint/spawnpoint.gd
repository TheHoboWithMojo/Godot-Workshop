@icon("res://assets/Icons/16x16/crosshair.png")
extends Marker2D
class_name SpawnPoint

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Data.game_data[Data.PROPERTIES.RELOAD_DATA]["last_position"] = global_position
