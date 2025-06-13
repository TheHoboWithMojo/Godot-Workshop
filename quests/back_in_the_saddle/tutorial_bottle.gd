extends Node2D
@onready var health_component: HealthComponent = $HealthComponent

func _ready() -> void:
	if not Global.quest_manager.back_in_the_saddle.shoot_the_bottles.is_complete():
		health_component.died.connect(_on_death)

func _on_death() -> void:
	Global.quest_manager.back_in_the_saddle.bottle_shot.emit()
