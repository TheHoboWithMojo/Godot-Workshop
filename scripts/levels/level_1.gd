extends Node2D

@export var spawn_point: Marker2D
@export var level_two: PackedScene
@export var level_three: PackedScene

@onready var spawn_point_pos = spawn_point.position

var door1_player_in_range: bool = false
var door2_player_in_range: bool = false

func _ready() -> void:
	add_to_group("levels")

func _process(_delta: float) -> void:
	# Check for door 1 interaction
	if door1_player_in_range and Input.is_action_just_pressed("interact"):
		Global.switch_to_level(self, level_two)
	
	# Check for door 2 interaction
	if door2_player_in_range and Input.is_action_just_pressed("interact"):
		Global.switch_to_level(self, level_three)

func _on_door_1_body_entered(body: Node2D) -> void:
	if body == Global.player:
		door1_player_in_range = true

func _on_door_1_body_exited(body: Node2D) -> void:
	if body == Global.player:
		door1_player_in_range = false

func _on_door_2_body_entered(body: Node2D) -> void:
	if body == Global.player:
		door2_player_in_range = true

func _on_door_2_body_exited(body: Node2D) -> void:
	if body == Global.player:
		door2_player_in_range = false
