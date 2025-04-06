extends Control

@export_group("Config")
@export var active: bool = true

@export_group("Labels")
@export var background: ColorRect
@export var health: Label
@export var speed: Label
@export var accomplishments: Label
@export var experience: Label
@export var crit: Label
@export var personality: Label
@export var damage: Label

@onready var buttons_box: VBoxContainer = $ButtonsBox
@onready var is_menu_open: bool = false
@onready var show_player_stats: bool = false
@onready var show_frames: bool = false

func _ready() -> void:
	await Global.active_and_ready(self, active)
	self.visible = false # If active, make sure menu starts invisible
	clear_data()

func _process(delta: float) -> void:
	# Get the target position
	var screen_pos: Vector2 = Global.player_camera.get_screen_center_position()
	var target_position: Vector2 = screen_pos - (get_rect().size / 2)
	
	# Smoothly move towards the target position
	global_position = global_position.lerp(target_position, 10 * delta)
	
	# Position the background at the top-left of the VBoxContainer
	background.position = buttons_box.position
	
	# Then resize it to match the VBoxContainer
	background.size.x = buttons_box.size.x
	background.size.y = buttons_box.size.y
	
	# Handle menu visibility
	if not is_menu_open:
		if Input.is_action_just_pressed("open_debug_menu"):
			self.visible = true
			is_menu_open = true
	else:
		if Input.is_action_just_pressed("open_debug_menu"):
			self.visible = false
			is_menu_open = false
			
	if show_player_stats or show_frames:
		update_stat_labels()

func update_stat_labels() -> void:
	health.text = "Health:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["health"])
	speed.text = "Speed:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["speed"])
	accomplishments.text = "Accomplishments:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["accomplishments"])
	experience.text = "Exp:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["exp"])
	crit.text = "Crit:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["crit"])
	personality.text = "Personality:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["personality"])
	damage.text = "Damage:\n " + Debug.get_dict_as_pretty_string(Data.game_data["stats"]["damage"])
	
func clear_data() -> void:
	health.text = ""
	speed.text = ""
	accomplishments.text = ""
	experience.text = ""
	crit.text = ""
	personality.text = ""
	damage.text = ""

func _on_pause_button_toggled(toggled_on: bool) -> void:
	get_tree().paused = toggled_on

func _on_show_frames_button_toggled(toggled_on: bool) -> void:
	show_frames = toggled_on
	if not show_frames:
		clear_data()

func _on_show_player_stats_button_toggled(toggled_on: bool) -> void:
	show_player_stats = toggled_on
	if not show_player_stats:
		clear_data()
	else:
		update_stat_labels()

func _on_save_game_button_pressed() -> void:
	Data.save_data_changes()
	await Data.data_saved

func _on_spawn_enemies_button_toggled(toggled_on: bool) -> void:
	Global.game_manager.spawn_enemies = !toggled_on
