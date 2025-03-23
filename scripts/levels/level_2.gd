extends Node2D

@export var spawn_point: Marker2D
@export var tiles: TileMapLayer
@onready var spawn_point_pos = spawn_point.position

func _ready() -> void:
	add_to_group("levels")
	Global.player.position = spawn_point_pos
