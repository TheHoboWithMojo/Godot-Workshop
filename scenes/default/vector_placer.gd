extends Control

@onready var popup: Window = $VBoxContainer/NamePopup
@onready var input_box: LineEdit = $VBoxContainer/NamePopup/Control/VBoxContainer/LineEdit
@onready var coordinate_printer: RichTextLabel = $CoordinatePrinter
@export var show_coords: bool = true
@export var ask_for_name: bool = true
@export var save_selection: bool = true
@export var level: Levels.LEVELS
@export var enabled: bool = true
var save_path: String = ""

var processing: bool = false
var mouse_pos: Vector2


var name_vector_dict: Dictionary[String, Vector2] = {

}

func _ready() -> void:
	if not enabled:
		queue_free()
	# Make Control fill the screen
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Force input to register
	mouse_filter = Control.MOUSE_FILTER_STOP

	if save_selection:
		assert(level != Levels.LEVELS.UNASSIGNED, Debug.define_error("To save with the vector placer the level you're in must be declared", self))
		save_path = Levels.get_level_path(level).replace(".tscn", "_navpoints.txt")

	popup.hide()

func _process(_delta: float) -> void:
	# Follow mouse if enabled
	if not show_coords:
		coordinate_printer.set_physics_process(false)

func _on_gui_input(event: InputEvent) -> void:
	if not processing and event.is_action_pressed("place_point"):
		processing = true
		if not ask_for_name:
			print(get_global_mouse_position())
			processing = false
			return
		mouse_pos = get_global_mouse_position()

		input_box.text = ""
		input_box.grab_focus()
		Player.set_movement_enabled(false)
		popup.popup_centered()
		popup.show()

func _on_line_edit_text_submitted(new_text: String) -> void:
	var nomen: String = new_text.strip_edges()
	if nomen.to_lower() == "c":
		popup.hide()
		processing = false
		Player.set_movement_enabled(true)
		return
	if nomen.to_lower() == "s":
		if not name_vector_dict:
			Debug.throw_warning("Tried to save an empty name_vector_dict", self)
			popup.hide()
			processing = false
			Player.set_movement_enabled(true)
			return

		var merged_dict: Dictionary = {}

		# Load existing data if it exists
		if not FileAccess.file_exists(save_path):

			var old_dict: Dictionary = Data.load_json_file(save_path)
			merged_dict = old_dict.duplicate(true)  # deep copy just in case

			for key: String in name_vector_dict.keys():
				if key in old_dict:
					print("[Vector Placer] Vector %s for level %s has been overridden" % [key, Levels.get_level_name(level)],
					"(Changed from %s to %s)" % [str(old_dict[key]), str(name_vector_dict[key])])
				merged_dict[key] = name_vector_dict[key]
		else:
			merged_dict = name_vector_dict.duplicate(true)
			Data.save_json(merged_dict, save_path)
			print("[Vector Placer] Vector data successfully saved to", save_path)

	name_vector_dict[nomen] = mouse_pos
	print(nomen, " Vector2", mouse_pos)
	popup.hide()
	processing = false
	Player.set_movement_enabled(true)

func _on_name_popup_close_requested() -> void:
	# Prevent closing via title bar or external click
	pass
