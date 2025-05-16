extends Control
@onready var count: RichTextLabel = $SPECIAL/Title/Count
@onready var special: VBoxContainer = $SPECIAL
@onready var confirm: VBoxContainer = $Confirm
@onready var confirm_button: Button = $SPECIAL/Confirm/Button
@onready var points: int = 20
@onready var strength: int = 5
@onready var perception: int = 5
@onready var endurance: int = 5
@onready var charisma: int = 5
@onready var intelligence: int = 5
@onready var agility: int = 5
@onready var luck: int = 5

func _ready() -> void:
	confirm.set_visible(false)

func _set_stat(stat: String, change: int) -> void:
	var new_value: int
	var label: RichTextLabel = null

	match stat:
		"s":
			new_value = strength + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				strength = new_value
				label = $SPECIAL/Strength/RichTextLabel2
		"p":
			new_value = perception + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				perception = new_value
				label = $SPECIAL/Perception/RichTextLabel2
		"e":
			new_value = endurance + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				endurance = new_value
				label = $SPECIAL/Endurance/RichTextLabel2
		"c":
			new_value = charisma + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				charisma = new_value
				label = $SPECIAL/Charisma/RichTextLabel2
		"i":
			new_value = intelligence + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				intelligence = new_value
				label = $SPECIAL/Intelligence/RichTextLabel2
		"a":
			new_value = agility + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				agility = new_value
				label = $SPECIAL/Agility/RichTextLabel2
		"l":
			new_value = luck + change
			if new_value >= 1 and new_value <= 10 and points - change >= 0:
				luck = new_value
				label = $SPECIAL/Luck/RichTextLabel2

	# Only update UI if the stat actually changed
	if label != null:
		label.set_text(str(new_value))
		points -= change
		count.set_text(str(points))
		
func _update_stats() -> void:
	Player.set_stat(Player.STATS.STRENGTH, strength)
	Player.set_stat(Player.STATS.PERCEPTION, perception)
	Player.set_stat(Player.STATS.ENDURANCE, endurance)
	Player.set_stat(Player.STATS.CHARISMA, charisma)
	Player.set_stat(Player.STATS.INTELLIGENCE, intelligence)
	Player.set_stat(Player.STATS.AGILITY, agility)
	Player.set_stat(Player.STATS.LUCK, luck)


# Signal Handlers
func _on_s_down_pressed() -> void:
	_set_stat("s", -1)


func _on_s_up_pressed() -> void:
	_set_stat("s", 1)


func _on_p_down_pressed() -> void:
	_set_stat("p", -1)


func _on_p_up_pressed() -> void:
	_set_stat("p", 1)


func _on_e_down_pressed() -> void:
	_set_stat("e", -1)


func _on_e_up_pressed() -> void:
	_set_stat("e", 1)


func _on_c_down_pressed() -> void:
	_set_stat("c", -1)


func _on_c_up_pressed() -> void:
	_set_stat("c", 1)


func _on_i_down_pressed() -> void:
	_set_stat("i", -1)


func _on_i_up_pressed() -> void:
	_set_stat("i", 1)


func _on_a_down_pressed() -> void:
	_set_stat("a", -1)


func _on_a_up_pressed() -> void:
	_set_stat("a", 1)


func _on_l_down_pressed() -> void:
	_set_stat("l", -1)


func _on_l_up_pressed() -> void:
	_set_stat("l", 1)


func _on_no_pressed() -> void:
	confirm.set_visible(false)
	special.set_visible(true)


func _on_yes_pressed() -> void:
	_update_stats()
	self.set_visible(false)
	self.queue_free()


func _on_button_pressed() -> void:
	special.set_visible(false)
	confirm.set_visible(true)
