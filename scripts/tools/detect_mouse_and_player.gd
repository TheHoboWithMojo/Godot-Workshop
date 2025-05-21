extends Area2D
# Automatically connects signals in _ready

@export var receiver: Node2D
@export_group("Detection")
@export var detect_player: bool = true
@export var detect_mouse: bool = true
@export var ignored_menu: Control
@export_group("Signal")
@export var signal_receiver: bool = true
@export var set_touching_to_self: bool = false
@export var emit_self_as_argument: bool = false

signal player_entered_area
signal player_exited_area
signal mouse_entered_area
signal mouse_exited_area

var ignored_zone: Rect2

func _ready() -> void:
	if detect_player:
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)
	if detect_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	if ignored_menu:
		set_ignored_menu(ignored_menu)

func _on_body_entered(body: Node2D) -> void:
	if body == Global.player:
		Global.player_touching_node = self if set_touching_to_self else receiver
		if signal_receiver:
			if emit_self_as_argument:
				player_entered_area.emit(self)
			else:
				player_entered_area.emit()

func _on_body_exited(body: Node2D) -> void:
	if body == Global.player:
		if not get_overlapping_bodies().has(Global.player):
			Global.player_touching_node = null
			if signal_receiver:
				if emit_self_as_argument:
					player_exited_area.emit(self)
				else:
					player_exited_area.emit()

func _on_mouse_entered() -> void:
	Global.mouse_touching_node = self if set_touching_to_self else receiver
	if signal_receiver:
		if not emit_self_as_argument:
			mouse_entered_area.emit()
			return
		mouse_entered_area.emit(self)


func _on_mouse_exited() -> void:
	if ignored_menu and ignored_zone.has_point(get_global_mouse_position()):
		return
	Global.mouse_touching_node = null
	if signal_receiver:
		if not emit_self_as_argument:
			mouse_exited_area.emit()
			return
		mouse_exited_area.emit(self)

func set_ignored_menu(menu: Control) -> void:
	ignored_menu = menu
	ignored_zone = ignored_menu.get_global_rect()
