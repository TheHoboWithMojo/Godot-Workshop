extends Node

@export var debugging: bool = true

signal inventory_updated

var inventory_size: int
var weight_limit: int

enum INVENTORY_SLOTS {
	UNASSIGNED,
	SLOT_1, SLOT_2, SLOT_3, SLOT_4, SLOT_5,
	SLOT_6, SLOT_7, SLOT_8, SLOT_9, SLOT_10,
	SLOT_11, SLOT_12, SLOT_13, SLOT_14, SLOT_15,
	SLOT_16, SLOT_17, SLOT_18, SLOT_19, SLOT_20
}

var player_inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = {
	INVENTORY_SLOTS.SLOT_1: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_2: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_3: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_4: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_5: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_6: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_7: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_8: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_9: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_10: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_11: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_12: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_13: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_14: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_15: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_16: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_17: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_18: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_19: InventorySlotData.new(),
	INVENTORY_SLOTS.SLOT_20: InventorySlotData.new(),
}

func _ready() -> void:
	await Global.ready_to_start()


func get_items_from_slot(slot: INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Array[Node]:
	var item_count: int = get_inventory_slot_item_count(slot, inventory_dict)
	var item_id: int = get_inventory_slot_item_id(slot, inventory_dict)
	if not item_count:
		Debug.debug("Tried to retrieve item in empty slot '%s'" % slot, self, "get_items_from_slot")
		return []
	var item: Node = Items.get_item_node(item_id)
	if not item:
		Debug.debug("Failed to retrieve the item with id '%s'" % item, self, "get_items_from_slot")
		return []
	var items_array: Array[Node]
	for item_instance: int in item_count: items_array.append(item.duplicate(true))
	return items_array


func get_inventory_slot_data(slot: Inventory.INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> InventorySlotData:
	return inventory_dict[slot]


func get_inventory_slot_item_id(slot: INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Items.ITEMS:
	return get_inventory_slot_data(slot, inventory_dict).get_item_id()


func get_inventory_slot_item_count(slot: INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> int:
	return get_inventory_slot_data(slot, inventory_dict).get_item_count()


func is_inventory_slot_occupied(slot: INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> bool:
	return not get_inventory_slot_data(slot, inventory_dict).is_cleared()


func find_all_inventory_slots_with_item(item: Items.ITEMS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Array[INVENTORY_SLOTS]:
	return get_filled_inventory_slots(inventory_dict).filter(func(slot: INVENTORY_SLOTS) -> bool: return get_inventory_slot_item_id(slot, inventory_dict) == item)


func get_filled_inventory_slots(inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Array[INVENTORY_SLOTS]:
	#print("\nCALLED")
	#inventory_dict.values().map(func(slot: InventorySlotData) -> void: return print(slot.is_cleared()))
	return inventory_dict.keys().filter(func(slot: INVENTORY_SLOTS) -> bool: return is_inventory_slot_occupied(slot, inventory_dict))


func get_total_num_item_in_inventory(item: Items.ITEMS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> int:
	var total: int = 0
	var slots_with_item: Array[INVENTORY_SLOTS] = find_all_inventory_slots_with_item(item)
	for slot: INVENTORY_SLOTS in slots_with_item: total += get_inventory_slot_data(slot, inventory_dict).get_item_count()
	return total


func get_all_items_ids_in_inventory(inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Array[Items.ITEMS]:
	return get_filled_inventory_slots(inventory_dict).map(func(slot: INVENTORY_SLOTS) -> Items.ITEMS: return get_inventory_slot_data(slot, inventory_dict).get_item_id())


func get_unfilled_inventory_slots(inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Array[INVENTORY_SLOTS]:
	return inventory_dict.keys().filter(func(slot: INVENTORY_SLOTS) -> bool: return not is_inventory_slot_occupied(slot, inventory_dict))


# returns the inventory with all items of the same type grouped together and the rest of the slots emptied ie 1. 4 strawberries 2. 3 oranges. 3. Vector2.ZERO 4. .... 10. Vector2.ZERO
func get_consolidated_inventory(inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> Dictionary[INVENTORY_SLOTS, InventorySlotData]:
	var consolidated_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData]
	var consolidated_items: Array[Items.ITEMS] = []
	var slot_to_fill: int = 1
	for slot: INVENTORY_SLOTS in get_filled_inventory_slots(inventory_dict):
		var slotted_item: Items.ITEMS = get_inventory_slot_item_id(slot)
		if slotted_item in consolidated_items: continue
		consolidated_items.append(slotted_item)
		var slotted_item_total: int = get_total_num_item_in_inventory(slotted_item, inventory_dict)
		consolidated_dict[slot_to_fill] = InventorySlotData.new(slotted_item, slotted_item_total)
		slot_to_fill += 1
	@warning_ignore("int_as_enum_without_cast")
	for slot: INVENTORY_SLOTS in range(slot_to_fill, inventory_dict.size() + 1):
		consolidated_dict[slot_to_fill] = InventorySlotData.new()
		slot_to_fill += 1
	return consolidated_dict


enum ORGANIZATION_MODES { ALPHABETICAL }
func organize_inventory(inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict, organization_mode: ORGANIZATION_MODES = ORGANIZATION_MODES.ALPHABETICAL) -> void:
	var consolidated_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = get_consolidated_inventory(inventory_dict)
	var organized_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData]
	match(organization_mode):
		ORGANIZATION_MODES.ALPHABETICAL:
			var alphebetized_items: Array = get_filled_inventory_slots(consolidated_dict).map(func(slot: INVENTORY_SLOTS) -> String: return get_inventory_slot_data(slot, consolidated_dict).get_item_name())
			alphebetized_items.sort()
			var num_filled_slots: int = alphebetized_items.size()
			var _inventory_size: int = consolidated_dict.keys().size()
			for slot: INVENTORY_SLOTS in consolidated_dict:
				var data: InventorySlotData = get_inventory_slot_data(slot, consolidated_dict)
				if data.is_cleared():
					break
				organized_dict[alphebetized_items.find(data.get_item_name()) + 1] = consolidated_dict[slot]
			@warning_ignore("int_as_enum_without_cast")
			for slot: INVENTORY_SLOTS in range(num_filled_slots + 1, _inventory_size + 1):
				organized_dict[slot] = InventorySlotData.new()
	inventory_dict.clear()
	for key: INVENTORY_SLOTS in organized_dict:
		inventory_dict[key] = organized_dict[key]
	inventory_updated.emit()


func swap_inventory_slot_contents(current_slot: INVENTORY_SLOTS, new_slot: INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> bool:
	if new_slot == current_slot:
		Debug.debug("Tried to move a slot to the same position" % [current_slot, new_slot], self, "change_item_slot")
		return false
	var current_slot_item_data: InventorySlotData = get_inventory_slot_data(current_slot, inventory_dict)
	var current_slot_item_name: String = current_slot_item_data.get_item_name()
	if current_slot_item_data.is_cleared():
		Debug.debug("Tried to move a nonexistent item in slot %s to slot %s" % [current_slot, new_slot], self, "change_item_slot")
		return false
	var new_slot_item_data: InventorySlotData = get_inventory_slot_data(new_slot, inventory_dict)
	if not new_slot_item_data.is_cleared():
		swap_inventory_slot_contents(new_slot, current_slot)
	new_slot_item_data.change_item_data(current_slot_item_data.get_item_id(), current_slot_item_data.get_item_count())
	current_slot_item_data.clear_data()
	Debug.debug("Successfully moved item '%s' from slot '%s' to slot '%s'!" % [current_slot_item_name, current_slot, new_slot], self, "change_item_slot")
	inventory_updated.emit()
	return true


func add_item_to_inventory(item_id: Items.ITEMS, item_count: int = 1, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> void:
	if item_count < 0:
		Debug.debug("Tried to add a negative amount of item '%s' to inventory" % [item_count], self, "add_item_to_inventory")
		return
	if item_id == Items.ITEMS.UNASSIGNED:
		Debug.debug("Tried to add an unassigned item to inventory" % [item_count], self, "add_item_to_inventory")
		return
	Debug.debug("Attempting to add item '%s' of quantity '%s' to an inventory" % [Items.get_item_name(item_id), item_count], self, "add_item_to_inventory")
	var first_empty_slot: INVENTORY_SLOTS = _get_first_empty_inventory_slot(inventory_dict)
	var first_same_item_slot: INVENTORY_SLOTS = _get_first_inventory_slot_with_item(item_id, inventory_dict)
	if first_same_item_slot:
		Debug.debug("Copy of item '%s' was found in slot '%s', merging..." % [Items.get_item_name(item_id), first_same_item_slot], self, "add_item_to_inventory")
		change_inventory_slot_item_count(first_same_item_slot, item_count, inventory_dict)
		inventory_updated.emit()
	elif first_empty_slot:
		Debug.debug("No copy of item '%s' was found, adding to slot '%s'" % [Items.get_item_name(item_id), first_empty_slot], self, "add_item_to_inventory")
		_add_item_to_slot(item_id, item_count, first_empty_slot, false, inventory_dict)
		inventory_updated.emit()
	Debug.debug("Failed to add item '%s' to inventory due to lack of space." % [Items.get_item_name(item_id)], self, "add_item_to_inventory")


func clear_inventory_slot(slot: INVENTORY_SLOTS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> void:
	inventory_dict[slot].clear_data()


func change_inventory_slot_item_count(slot: INVENTORY_SLOTS, change: int = 1, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> void:
	if not is_inventory_slot_occupied(slot, inventory_dict):
		Debug.debug("Tried to change the item count of an empty slot by %s" % change, self, "change_inventory_slot_item_count")
		return
	var item: Items.ITEMS = get_inventory_slot_item_id(slot, inventory_dict)
	var new_item_count: int = get_inventory_slot_item_count(slot, inventory_dict) + change
	if  new_item_count < 0:
		new_item_count = 0
		Debug.debug("Tried to set count of item '%s' in slot '%s' to '%s', defaulting to 0" % [item, slot, new_item_count], self, "change_inventory_slot_item_count")
	inventory_dict[slot] = InventorySlotData.new(item, new_item_count)


func _add_item_to_slot(item_id: Items.ITEMS, item_count: int, slot: INVENTORY_SLOTS, add_if_occupied: bool = false, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> void:
	if add_if_occupied or not is_inventory_slot_occupied(slot, inventory_dict): inventory_dict[slot] = InventorySlotData.new(item_id, item_count)


func _get_first_empty_inventory_slot(inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> INVENTORY_SLOTS:
	for slot: INVENTORY_SLOTS in inventory_dict: if not is_inventory_slot_occupied(slot, inventory_dict): return slot
	return INVENTORY_SLOTS.UNASSIGNED


func _get_first_inventory_slot_with_item(item_id: Items.ITEMS, inventory_dict: Dictionary[INVENTORY_SLOTS, InventorySlotData] = player_inventory_dict) -> INVENTORY_SLOTS:
	for slot: INVENTORY_SLOTS in inventory_dict: if inventory_dict[slot].get_item_id() == item_id: return slot
	return INVENTORY_SLOTS.UNASSIGNED


class InventorySlotData:
	var item_id: Items.ITEMS = Items.ITEMS.UNASSIGNED:
		set(value):
			item_id = value
			#prints("new item id", item_id)
	var item_count: int = 0

	func _init(_item_id: Items.ITEMS = Items.ITEMS.UNASSIGNED, _item_count: int = 0) -> void:
		item_id = _item_id
		item_count = _item_count


	func clear_data() -> void:
		item_id = Items.ITEMS.UNASSIGNED
		item_count = 0


	func change_item_data(new_item_id: Items.ITEMS, new_item_count: int = 1) -> void:
		item_id = new_item_id
		item_count = new_item_count


	func get_item_id() -> Items.ITEMS:
		return item_id


	func get_item_name() -> String:
		return Items.get_item_name(item_id)


	func get_item_count() -> int:
		return item_count


	func get_item_node() -> Node:
		return Items.get_item_node(item_id)


	func get_item_texture() -> Texture2D:
		return Items.get_item_texture(item_id)


	func is_cleared() -> bool:
		return item_id == Items.ITEMS.UNASSIGNED and item_count == 0
