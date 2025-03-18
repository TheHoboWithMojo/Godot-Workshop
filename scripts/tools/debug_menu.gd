extends Control

@export var is_active: bool = false
@export var pause_button: CheckButton
@export var player_data_label: Label
@export var show_player_data_button: CheckButton
@export var show_frames_button: CheckButton
@export var frame_data_label: Label

@onready var is_menu_open: bool = false
@onready var show_player_data: bool = false
@onready var show_frame_data: bool = false

func _ready() -> void:
	if not is_active:
		self.queue_free() # Remove debug menu from tree if not activated
		return
	else:
		self.visible = false

func _process(_delta: float) -> void:
	# Get the player cameras position
	var screen_pos = Global.player_camera.get_screen_center_position()
	
	# Center the debug menu on the player with optional offset
	global_position = screen_pos - (size / 2)
	
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
		
		if show_player_data == true:
			player_data_label.text = Debug.get_dict_as_pretty_string(Data.game_data["player stats"])
			
		if show_frame_data == true:
			frame_data_label.text = "Frames: " + str(Global.frames)

func _on_pause_button_toggled(toggled_on: bool) -> void:
	get_tree().paused = toggled_on


func _on_show_data_button_toggled(toggled_on: bool) -> void:
	show_player_data = toggled_on
	if show_player_data == false:
		player_data_label.text = ""
	
func _on_show_frames_button_toggled(toggled_on: bool) -> void:
	show_frame_data = toggled_on
	if show_frame_data == false:
		frame_data_label.text = ""
