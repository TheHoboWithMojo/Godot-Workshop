extends Being

var _conversing: bool
var _reputation: int

func _init(
		conversing: bool,
		reputation: int,
		name: String,
		sprite: AnimatedSprite2D,
		health: int,
		collision_shape: CollisionShape2D,
		area: Area2D,
		alive: bool,
		hostile: bool,
		animation_player: AnimationPlayer
	):
	print("[NPC] Constructor called")
	print("[NPC] Initializing: Conversing=%s, Reputation=%s" % [conversing, reputation])
	
	super(sprite, health, collision_shape, area, alive, animation_player, name, hostile)
	
	_conversing = conversing
	_reputation = reputation

func converse() -> void:
	print("[NPC] Converse method called")

# IMortal interface methods implemented from parent
func take_damage(damage: int) -> void:
	print("[Being] %s takes %s damage" % [name, damage])
	health -= damage

func heal(heal_amount: int) -> void:
	print("[Being] %s heals %s health" % [name, heal_amount])
	health += heal_amount
