extends Control

var in_inventory: bool = false
@onready var button: Button = $Grid/Button


func _ready() -> void:
	set_visible(false)
	Inventory.add_item_to_inventory(Items.ITEMS.ORB, 1, Inventory.player_inventory_dict)
	Inventory.add_item_to_inventory(Items.ITEMS.FIREBALL, 5, Inventory.player_inventory_dict)
	Inventory.add_item_to_inventory(Items.ITEMS.ORB, 1, Inventory.player_inventory_dict)
	button.pressed.connect(_on_press)


func _on_press() -> void:
	Inventory.organize_inventory(Inventory.player_inventory_dict)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("open_inventory") and not in_inventory:
		set_visible(true)
		Global.enter_menu()
		in_inventory = true
	elif Input.is_action_just_pressed("open_inventory") and in_inventory:
		set_visible(false)
		Global.exit_menu()
		in_inventory = false
