extends CharacterBody2D

@export var quest_stage: STAGE
var quest_ref: BackInTheSaddle = null

enum STAGE {WELL1, WELL2}

@onready var health_component: HealthComponent = $HealthComponent


func _ready() -> void:
	quest_ref = Global.quest_manager.get_quest_node(Quests.QUESTS.BACK_IN_THE_SADDLE)
	if quest_ref.is_complete():
		queue_free()
	health_component.died.connect(_on_death)
	match(quest_stage):
		STAGE.WELL1:
			if quest_ref.kill_geckos_at_first_well.is_complete():
				queue_free()
		STAGE.WELL2:
			if quest_ref.kill_geckos_at_second_well.is_complete():
				queue_free()

func _on_death() -> void:
	match(quest_stage):
		STAGE.WELL1:
			quest_ref.first_well_gecko_killed.emit()
		STAGE.WELL2:
			quest_ref.second_well_gecko_killed.emit()
