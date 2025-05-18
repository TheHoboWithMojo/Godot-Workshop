extends Area2D
# this script automatically connect signals. dont do it in the node menu
@export var receiver: Node2D # Ref the signal receiver
@export_group("Detection")
@export var detect_player: bool = true
@export var detect_mouse: bool = true
@export_group("Signal")
@export var signal_receiver: bool = true # signals to receiver upon entry
@export var set_touching_to_self: bool = false # sets player_touching to the detector, not the receiver (good for levels with multiple detectors)
@export var emit_self_as_argument: bool = false # sends area as an argument into signals

signal player_entered_area
signal player_exited_area
signal mouse_entered_area
signal mouse_exited_area

func _ready() -> void:
	if detect_player:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	if detect_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)


func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		if set_touching_to_self:
			Global.player_touching_node = self
		else:
			Global.player_touching_node = receiver
		if signal_receiver:
			if emit_self_as_argument:
				player_entered_area.emit(self)
			else:
				player_entered_area.emit()


func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = null
		if signal_receiver:
			if emit_self_as_argument:
				player_exited_area.emit(self)
			else:
				player_exited_area.emit()


func _on_mouse_entered() -> void:
	if set_touching_to_self:
		Global.mouse_touching_node = self
	else:
		Global.mouse_touching_node = receiver
	if signal_receiver:
		if emit_self_as_argument:
			mouse_entered_area.emit(self)
		else:
			mouse_entered_area.emit()


func _on_mouse_exited() -> void:
	Global.mouse_touching_node = null
	if signal_receiver:
		if emit_self_as_argument:
			mouse_exited_area.emit(self)
		else:
			mouse_exited_area.emit()
