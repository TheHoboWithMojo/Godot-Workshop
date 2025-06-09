extends Area2D

@export var projectile: PackedScene
@export var audio: AudioStreamPlayer2D
@export var sprite: Sprite2D
@export var collision: CollisionShape2D

@onready var collected: bool = false # only runs once

func _ready() -> void:
	if projectile.get_path() in Data.game_data["reload_data"]["acquired_weapons"]: # delete book if already collected
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		if not collected:
			collected = true
			collect_projectile()
			audio.play()
			sprite.visible = false
			if audio.playing:
				await audio.finished
			queue_free()
