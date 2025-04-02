# Creates an in game menu for pausing, and for reading game data in real time
extends Control

@export var active: bool = true
@export var pause_button: CheckButton
@export var data_label: Label

@onready var is_menu_open: bool = false
@onready var show_player_stats: bool = false
@onready var show_frames: bool = false

func _ready() -> void:
	await Global.active_and_ready(self, active)
	self.visible = false # If active, make sure menu starts invisible

func _process(delta: float) -> void:
	# Get the target position
	var screen_pos: Vector2 = Global.player_camera.get_screen_center_position()
	var target_position: Vector2 = screen_pos - (size / 2)

	# Smoothly move towards the target position
	global_position = global_position.lerp(target_position, 10 * delta)
	
	# Handle menu visibility
	if not is_menu_open:
		if Input.is_action_just_pressed("open_debug_menu"):
			self.visible = true
			is_menu_open = true
	else:
		if Input.is_action_just_pressed("open_debug_menu"):
			self.visible = false
			is_menu_open = false
			
			pause_button.button_pressed = false # Make sure the game unpauses
		
		if show_player_stats or show_frames:
			var data: String = ""
			if show_player_stats:
				data = data + "Player Stats:\n" + Debug.get_dict_as_pretty_string(Data.game_data["stats"]) + "\n"
			if show_frames == true:
				data = data + "Frames: " + str(Global.frames) + "\n"
			data_label.text = data

				
func _on_pause_button_toggled(toggled_on: bool) -> void:
	get_tree().paused = toggled_on
	
func _on_show_frames_button_toggled(toggled_on: bool) -> void:
	show_frames = toggled_on
	if show_frames == false:
		data_label.text = ""

func _on_show_player_stats_button_toggled(toggled_on: bool) -> void:
	show_player_stats = toggled_on
	if show_player_stats == false:
		data_label.text = ""

func _on_save_game_button_pressed() -> void:
	Data.save_data_changes()
	await Data.data_saved


func _on_spawn_enemies_button_toggled(toggled_on: bool) -> void:
	Global.game_manager.spawn_enemies = !toggled_on
