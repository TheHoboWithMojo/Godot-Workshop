extends Area2D

@export var projectile: PackedScene
@export var audio: AudioStreamPlayer2D
@export var sprite: Sprite2D
@export var collision: CollisionShape2D

var collected: bool = false # only runs once
func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		if not collected:
			collected = true
			Global.player.projectile = projectile
			audio.play()
			sprite.visible = false
			if audio.playing:
				await audio.finished
			queue_free()
