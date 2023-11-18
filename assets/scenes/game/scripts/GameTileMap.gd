class_name GameTileMap extends TileMap

@export var map_name: String
@export var spawn_points: Array[Vector2i]
var selected_tile: Vector2
var has_last_selected: bool = false
var reachables: Array = []
var attackables: Array = []
var movement_path: Array = []
var attack_targets: Array = []
var not_enough_ap: bool

enum TILE_LAYER {BACKGROUND, HIGHLIGHT, SELECT, HIGHLIGHT2}


func get_data_at(mapgrid: Vector2, data_name: String, fallback_value):
	var tile_data: TileData = get_cell_tile_data(0, mapgrid)
	return tile_data.get_custom_data(data_name) if not tile_data == null else fallback_value


func get_ap_cost_at(mapgrid: Vector2, fallback_value = -1):
	return get_data_at(mapgrid, "ap_cost", fallback_value)


func get_stat_mods_at(mapgrid: Vector2):
	return {
		"accuracy_mod": get_data_at(mapgrid, "accuracy_mod", 0),
		"evasion_mod": get_data_at(mapgrid, "evasion_mod", 0),
		"armor_mod": get_data_at(mapgrid, "armor_mod", 0)
	}

func select_tile(tile_mapgrid: Vector2):
	if has_last_selected == true:
		if tile_mapgrid == selected_tile:
			return
		set_cell(2, selected_tile, -1, get_cell_atlas_coords(0, selected_tile))
	has_last_selected = true
	selected_tile = tile_mapgrid
	set_cell(2, selected_tile, 2, Vector2i(0, 0))


func set_reachables(_reachables):
	hide_reachables()
	reachables = _reachables


func show_reachables():
	for reachable_tile in reachables:
		set_cell(TILE_LAYER.HIGHLIGHT, reachable_tile, 1, Vector2i(0, 0))


func hide_reachables():
	for reachable_tile in reachables:
		set_cell(TILE_LAYER.HIGHLIGHT, reachable_tile, -1, Vector2i(0, 0))


func set_movement_path(_movement_path, _not_enough_ap):
	hide_movement_path()
	movement_path = _movement_path
	not_enough_ap = _not_enough_ap


func show_movement_path():
	for tile in movement_path:
		set_cell(TILE_LAYER.HIGHLIGHT2, tile, 1, Vector2i(1, 0) if not_enough_ap else Vector2i(0, 1))


func hide_movement_path():
	for tile in movement_path:
		set_cell(TILE_LAYER.HIGHLIGHT2, tile, -1, Vector2i(1, 0) if not_enough_ap else Vector2i(0, 1))


func set_attackables(_attackables):
	hide_attackables()
	attackables = _attackables


func show_attackables():
	for attackable_tile in attackables:
		set_cell(TILE_LAYER.HIGHLIGHT, attackable_tile, 1, Vector2i(1, 1))


func hide_attackables():
	for attackable_tile in attackables:
		set_cell(TILE_LAYER.HIGHLIGHT, attackable_tile, -1, Vector2i(0, 0))


func set_attack_target(_attack_target, _not_enough_ap):
	hide_attack_target()
	attack_targets = _attack_target
	not_enough_ap = _not_enough_ap


func show_attack_target():
	for attack_target in attack_targets:
		set_cell(TILE_LAYER.HIGHLIGHT2, attack_target, 1, Vector2i(0, 1) if not_enough_ap else Vector2i(1, 0))


func hide_attack_target():
	for attack_target in attack_targets:
		set_cell(TILE_LAYER.HIGHLIGHT2, attack_target, -1, Vector2i(0, 1) if not_enough_ap else Vector2i(1, 0))
