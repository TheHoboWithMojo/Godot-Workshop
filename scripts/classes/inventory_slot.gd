class_name InventorySlot extends TextureButton

@export var slot_enum: Inventory.INVENTORY_SLOTS
@onready var count_label: RichTextLabel = $CountLabel
var current_data: Inventory.InventorySlotData
var current_item_id: Items.ITEMS
var current_item_count: int
var current_texture: Texture2D
var is_held_down: bool = false

func _ready() -> void:
	assert(slot_enum != Inventory.INVENTORY_SLOTS.UNASSIGNED and int(name.trim_prefix("SLOT")) == slot_enum, "%s != %s" % [name.trim_prefix("SLOT"), slot_enum ])
	Inventory.inventory_updated.connect(_on_inventory_updated)
	button_down.connect(_on_pressed)
	button_up.connect(_on_released)
	gui_input.connect(_on_gui_input)


func _on_pressed() -> void:
	is_held_down = true


func _on_released() -> void:
	is_held_down = false


var _is_processing: bool = false
func _on_gui_input(_event: InputEvent) -> void:
	if not is_held_down or _is_processing:
		return
	_is_processing = true
	await button_up
	for slot: InventorySlot in get_tree().get_nodes_in_group("slots") as Array[InventorySlot]:
		if slot == self: continue
		if slot.get_global_rect().has_point(get_global_mouse_position()):
			Inventory.swap_inventory_slot_contents(slot_enum, slot.slot_enum)
			_is_processing = false
			break
	_is_processing = false


func _on_inventory_updated() -> void:
	current_data = Inventory.get_inventory_slot_data(slot_enum)
	current_item_id = current_data.get_item_id()
	current_item_count = current_data.get_item_count()
	current_texture = current_data.get_item_texture() if current_data.get_item_texture() else load("res://scenes/main/player_manager/placeholder.png")
	count_label.set_text(str(current_item_count))
