extends Node2D
# Functions Related to Player Stats and Behavior
func aggro_conversers() -> void:
	for node: Node2D in Global.player.current_conversers:
		if "master" in node:
			node.master.set_hostile(true)

func get_stat(stat: String) -> float:
	var stat_category: String = Global._get_stat_category(stat)
	return Data.game_data["stats"][stat_category][stat] if stat_category else 0.0
	
func get_health() -> float:
	return get_stat("health")
	
func get_speed() -> float:
	return get_stat("speed")*get_stat("speed_mult")*Global.speed_mult

@onready var _damagable: bool = true
func damage(_damage: float) -> void:
	if _damagable:
		_damagable = false
		change_stat("health - %s" % [_damage])
		await Global.delay(self, 1.0) # IFRAMES
		_damagable = true

func heal(_heal: float) -> void:
	change_stat("health + %s" % [_heal])

func add_exp(exp_gain: int) -> void:
	change_stat("exp + %s" % [exp_gain*get_stat("exp_mult")])
	
func log_kill(exp_gain: int) -> void:
	add_exp(exp_gain)
	change_stat("enemies_killed + 1")

func add_perk(perk_name: String) -> void:
	perk_name = perk_name.capitalize()
	if not Data.game_data["perks"].has(perk_name):
		print("Could not find '", perk_name, "' in perks data")
		Debug.print_player_perks()
		return
		
	if Global._update_toggle_buff(perk_name, Data.game_data["perks"]):
		print(perk_name, " boolean buff was added!")

func change_stat(buff_string: String, debug: bool = false) -> void:
	var buffs: Array = Global._parse_buff_string(buff_string)
	for buff: Array in buffs:
		var stat: String = buff[0]
		var operator: String = buff[1]
		var value: float = buff[2]
		var stat_category: String = Global._get_stat_category(stat)
		
		if stat_category.is_empty():
			continue
			
		var original_stat_value: float = Data.game_data["stats"][stat_category][stat]
		var new_stat_value: float = Global._get_updated_stat(stat_category, stat, operator, value)
		
		if debug:
			Global._print_stat_change(stat, original_stat_value, new_stat_value)
