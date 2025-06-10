@icon("res://assets/Icons/16x16/world_hand.png")
extends Area2D
class_name TouchDetector
@export var monitored_parent: Node2D
@export var detect_player: bool = true
@export var detect_mouse: bool = true
@export var collider: Collider = null
@export_group("Tweaks")
@export var debugging: bool = false
@export var ignored_control: Control = null
@export var send_signal_to_parent: bool = true
@export var set_touching_to_self: bool = false
@export var emit_self_as_argument: bool = false

signal player_entered_area
signal player_exited_area
signal mouse_entered_area
signal mouse_exited_area

var ignored_zone: Rect2

func _ready() -> void:
	assert(monitored_parent != null, Debug.define_error("TouchDetector of inferred parent '%s' must explicitly reference a parent" % [get_parent().name], self))
	if not collider:
		collider = find_child("Collider")
		assert(collider != null, Debug.define_error("TouchDetector MUST reference a collider", monitored_parent))
		push_warning(Debug.define_error("TouchDetector collider was inferred", monitored_parent))
	collider.reparent(self)
	if detect_player:
		area_entered.connect(_on_area2d_entered)
		area_exited.connect(_on_area2d_exited)
	if detect_mouse:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	if ignored_control:
		set_ignored_control(ignored_control)


func _on_mouse_entered() -> void:
	Global.mouse_touching_node = self if set_touching_to_self else monitored_parent
	if send_signal_to_parent:
		if not emit_self_as_argument:
			mouse_entered_area.emit()
			return
		mouse_entered_area.emit(self)


func _on_mouse_exited() -> void:
	if ignored_control and ignored_zone.has_point(get_global_mouse_position()):
		return
	Global.mouse_touching_node = null
	if send_signal_to_parent:
		if not emit_self_as_argument:
			mouse_exited_area.emit()
			return
		mouse_exited_area.emit(self)

func set_ignored_control(menu: Control) -> void: # prevents the mouse_exited signal from procking when the mouse overlaps the control
	ignored_control = menu
	ignored_zone = ignored_control.get_global_rect()


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
