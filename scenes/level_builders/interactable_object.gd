extends StaticBody2D
@export_group("Nodes")
@export var sprite: Sprite2D
@export var collider: CollisionShape2D
@export var ibubble_collider: CollisionShape2D
@export_group("Events")
@export var repeat_event: bool = false
@export var play_timeline: bool = true
@export var timeline: Dialogue.TIMELINES
@export var play_scene: bool = false
@export var scene_path: String
@onready var ibubble: Area2D = $IBubble
@onready var scene: PackedScene

signal player_touched_me

func _ready() -> void:
	ibubble_collider.reparent(ibubble)
	await get_tree().process_frame
	scene = load(scene_path)

func _process(_delta: float) -> void:
	interact()

@onready var first_interaction: bool = true
@onready var interacting: bool = false
func interact() -> void:
	if not interacting:
		interacting = true
		if play_timeline and play_scene:
			Debug.throw_error(self, "interact", "object cannot play both a scene and timeline")
			return
		if timeline and play_timeline:
			while Global.is_touching_player(self):
				player_touched_me.emit()
				if Input.is_action_just_pressed("interact"):
					if await Dialogue.start(timeline):
						await Dialogic.timeline_ended
				await get_tree().process_frame
		if scene and play_scene:
			while Global.is_touching_player(self):
				player_touched_me.emit()
				if Input.is_action_just_pressed("interact"):
					var node: Node = scene.instantiate()
					get_tree().root.add_child(node)
					node.set_global_position(Global.player.global_position)
					if not repeat_event:
						scene = null
					return
				await get_tree().process_frame
		interacting = false
