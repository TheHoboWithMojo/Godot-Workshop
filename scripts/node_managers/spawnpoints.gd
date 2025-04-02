extends Marker2D

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Data.game_data["reload_data"]["last_position"] = self.global_position
