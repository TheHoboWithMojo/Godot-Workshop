@icon("res://assets/Icons/16x16/world_hand.png")
extends Area2D
class_name TouchDetector
@export_group("Essential")
@export var monitored_parent: Node2D
@export var detect_player: bool = true
@export var detect_mouse: bool = true
@export var collider: Collider = null
@export_group("Tweaks")
@export var debugging: bool = false
@export var ignored_menu: Control = null
@export var send_signal_to_parent: bool = true
@export var set_touching_to_self: bool = false
@export var emit_self_as_argument: bool = false

signal player_entered_area
signal player_exited_area
signal mouse_entered_area
signal mouse_exited_area

var ignored_zone: Rect2

func _ready() -> void:
	if not collider:
		collider = %Collider
		assert(collider != null, Debug.define_error("area2ds need hit detection", self))
	collider.reparent(self)
	assert(monitored_parent != null, Debug.define_error("all mouse/player detectors must have a parent to monitor", self))
	if detect_player:
		area_entered.connect(_on_area2d_entered)
		area_exited.connect(_on_area2d_exited)
	if detect_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	if ignored_menu:
		set_ignored_menu(ignored_menu)


func _on_mouse_entered() -> void:
	Global.mouse_touching_node = self if set_touching_to_self else monitored_parent
	if send_signal_to_parent:
		if not emit_self_as_argument:
			mouse_entered_area.emit()
			return
		mouse_entered_area.emit(self)


func _on_mouse_exited() -> void:
	if ignored_menu and ignored_zone.has_point(get_global_mouse_position()):
		return
	Global.mouse_touching_node = null
	if send_signal_to_parent:
		if not emit_self_as_argument:
			mouse_exited_area.emit()
			return
		mouse_exited_area.emit(self)

func set_ignored_menu(menu: Control) -> void: # prevents the mouse_exited signal from procking when the mouse overlaps the control
	ignored_menu = menu
	ignored_zone = ignored_menu.get_global_rect()


func set_monitored_parent(node: Node) -> void:
	monitored_parent = node


func get_collider() -> Collider:
	return $Collider


func _on_area2d_entered(area: Area2D) -> void:
	if area == Global.player_bubble:
		Debug.debug("player entered.", self, "_on_area2d_entered",)
		Global.player_touching_node = self if set_touching_to_self else monitored_parent
		if send_signal_to_parent:
			if emit_self_as_argument:
				player_entered_area.emit(self)
			else:
				player_entered_area.emit()


func _on_area2d_exited(area: Area2D) -> void:
	if area == Global.player_bubble:
		Debug.debug("player exited", self, "_on_area2d_exited")
		if not get_overlapping_areas().has(Global.player_bubble):
			Global.player_touching_node = null
			if send_signal_to_parent:
				if emit_self_as_argument:
					player_exited_area.emit(self)
				else:
					player_exited_area.emit()
