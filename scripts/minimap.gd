extends CanvasLayer

@onready var sub_viewport_container: SubViewportContainer = $UI/MarginContainer/SubViewportContainer
@onready var sub_viewport: SubViewport = $UI/MarginContainer/SubViewportContainer/SubViewport
@onready var minimap_camera: Camera2D = $UI/MarginContainer/SubViewportContainer/SubViewport/MinimapCamera
@onready var player_marker: ColorRect = $UI/MarginContainer/SubViewportContainer/SubViewport/PlayerMarker

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await Global.active_and_ready(self, true)
	if Global.game_manager.current_tile_map == null:
		await Global.game_manager.level_loaded
	var tilemap = Global.game_manager.current_tile_map
	var minimap_tilemap = tilemap.duplicate()
	var used_rect: Rect2i = tilemap.get_used_rect()
	setup_minimap(minimap_tilemap)
	set_minimap_limits(used_rect)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if Global.player:
		minimap_camera.global_position = lerp(minimap_camera.global_position, Global.player.global_position, 0.2)
		player_marker.global_position = Global.player.global_position
		

func setup_minimap(minimap_tilemap: TileMapLayer):
	sub_viewport.add_child(minimap_tilemap)
	
func set_minimap_limits(used_rect: Rect2i):
	minimap_camera.limit_left = used_rect.position.x * 16
	minimap_camera.limit_right = used_rect.position.y * 16
	minimap_camera.limit_top = (used_rect.position.x + used_rect.size.x) * 16
	minimap_camera.limit_bottom = (used_rect.position.y + used_rect.size.y) * 16
