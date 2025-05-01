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

func collect_projectile() -> void:
	if not projectile in Global.player.projectiles: # Check if the player already has the projectile
		Global.player.projectiles.append(projectile) # Add it if not
		Data.game_data["reload_data"]["acquired_weapons"].append(projectile.get_path())
		
		if Global.player.projectiles.size() == 1: # if its the first they pick up, set it as their active
			Global.player.current_projectile = projectile
