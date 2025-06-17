extends Node2D
@onready var health_component: HealthComponent = $HealthComponent
func _ready() -> void:
	if Quests.is_quest_completed(Quests.QUESTS.BACK_IN_THE_SADDLE):
		return
	health_component.died.connect(_on_death)

func _on_death() -> void:
	Global.quest_manager.back_in_the_saddle.bottle_shot.emit()
