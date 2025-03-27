extends CharacterBody2D
######## STATS #####################
@export var active: bool = true
@export var collision_on: bool = true
@export var hostile: bool = false
@export var debugging: bool
@export var base_speed: float = 3500.0
@export var base_damage: float = 10.0
@export var base_health: float = 30
@export var perception: float = 50.0
@export var EXP_ON_KILL: int = 10
@export var nomen: String = ""
@export var faction: String = ""

########## NODES #######################
@export var sprite: AnimatedSprite2D
@export var collider: CollisionShape2D
@export var area: Area2D
@export var health_bar: TextureProgressBar

####### RUNTIME VARIABLES ##############
@onready var controller: Object

func _ready() -> void:
	preload("res://dialogic/timelines/npc.dtl")
	preload("res://dialogic/characters/npc.dch")
	preload("res://dialogic/styles/default.tres")
	if hostile:
		add_to_group("enemies")
	else:
		health_bar.visible = false
		add_to_group("interactable")
		
	controller = Being.create_being(self)
	
	if not collision_on:
		controller.toggle_collision(false)
		
func _process(_delta: float) -> void:
	if not controller.is_alive():
		await controller.die(EXP_ON_KILL)
	
	health_bar.set_value(controller.health)
	
	converse()
	
	attack()

var first_time_hostile: bool = true
func _physics_process(delta: float) -> void:
	if controller.is_hostile():
		if first_time_hostile:
			var label = Label.new()
			label.text = "you killed my friends!"
			self.add_child(label)

		var vector_to_player =  Global.get_vector_to_player(self)
		var direction: Vector2 = vector_to_player.normalized()
		var detection_range: float = perception * 10
		
		if vector_to_player.length() < detection_range:
			velocity = direction * controller.speed * delta * Global.speed_mult
			if velocity.length() > 0:
				controller.play_animation("run")
			if direction.x < 0:
				controller.flip_sprite(true)
			else:
				controller.flip_sprite(false)
			
			move_and_slide()
	else:
		controller.play_animation("idle")

func converse():
	if controller.is_touching_player:
		if Global.player_touching_node == Global.cursor_touching_node:
			if Input.is_action_just_pressed("interact"):
					Global.start_dialog("npc")

func attack():
	if hostile:
		while controller.is_touching_player:
			Global.player.player_damaged.emit(base_damage)
			await Global.delay(self, 0.1) # avoid overload	

func _on_area_body_entered(body: Node2D) -> void:
	if body == Global.player:
		controller.is_touching_player = true
		Global.player_touching_node = area
		

func _on_area_body_exited(body: Node2D) -> void:
	if body == Global.player:
		controller.is_touching_player = false
		Global.player_touching_node = null

func _on_area_mouse_entered() -> void:
	Global.cursor_touching_node = area

func _on_area_mouse_exited() -> void:
	Global.cursor_touching_node = null
