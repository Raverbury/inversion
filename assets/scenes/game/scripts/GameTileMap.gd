class_name GameTileMap extends TileMap

@export var map_name: String
@export var spawn_points: Array[Vector2i]
@export var max_x_mapgrid: int
@export var min_x_mapgrid: int
@export var max_y_mapgrid: int
@export var min_y_mapgrid: int

var selected_tile: Vector2
var has_last_selected: bool = false
var reachables: Array = []
var attackables: Dictionary = {}
var movement_path: Array = []
var attack_targets: Array = []
var not_enough_ap: bool

const HIGHLIGHT_GREEN = Vector2i(0, 0)
const HIGHLIGHT_RED = Vector2i(1, 0)
const HIGHLIGHT_BLUE = Vector2i(0, 1)
const HIGHLIGHT_YELLOW = Vector2i(1, 1)

const HIGHLIGHT_SELECT_GREEN = Vector2i(0, 0)
const HIGHLIGHT_SELECT_RED = Vector2i(1, 0)
const HIGHLIGHT_SELECT_LIGHTBLUE = Vector2i(0, 1)
const HIGHLIGHT_SELECT_LIGHTYELLOW = Vector2i(1, 1)
const HIGHLIGHT_SELECT_PURPLE = Vector2i(0, 2)
const HIGHLIGHT_SELECT_ORANGE = Vector2i(1, 2)
const HIGHLIGHT_SELECT_WHITE = Vector2i(0, 3)
const HIGHLIGHT_SELECT_BLACK = Vector2i(1, 3)

const LAYER_SURFACE = 0
const LAYER_OBSTACLE = 1
const LAYER_DECORATION = 2
const LAYER_SELECT = 3
const LAYER_HIGHLIGHT = 4
const LAYER_HIGHLIGHT_SELECT = 5

const SOURCE_TILESET = 0
const SOURCE_SELECT = 1
const SOURCE_HIGHLIGHT = 2
const SOURCE_HIGHLIGHT_SELECT = 3


func get_data_at(mapgrid: Vector2, data_name: String, fallback_value):
	var tile_data: TileData = get_cell_tile_data(LAYER_OBSTACLE, mapgrid)
	if tile_data == null:
		tile_data = get_cell_tile_data(LAYER_SURFACE, mapgrid)
	return tile_data.get_custom_data(data_name) if not tile_data == null else fallback_value


func get_ap_cost_at(mapgrid: Vector2, fallback_value = -1):
	return get_data_at(mapgrid, "ap_cost", fallback_value)


func get_stat_mods_at(mapgrid: Vector2) -> TileStatBonus:
	return TileStatBonus.new(get_data_at(mapgrid, "accuracy_mod", 0),
		get_data_at(mapgrid, "evasion_mod", 0), get_data_at(mapgrid, "armor_mod", 0))


func get_atlas_coord_at(mapgrid: Vector2):
	var tile_data: TileData = get_cell_tile_data(LAYER_OBSTACLE, mapgrid)
	if tile_data == null:
		return get_cell_atlas_coords(LAYER_SURFACE, mapgrid) as Vector2
	return get_cell_atlas_coords(LAYER_OBSTACLE, mapgrid) as Vector2


func select_tile(tile_mapgrid: Vector2):
	if has_last_selected == true:
		if tile_mapgrid == selected_tile:
			return
		set_cell(LAYER_SELECT, selected_tile, -1, get_cell_atlas_coords(0, selected_tile))
	has_last_selected = true
	selected_tile = tile_mapgrid
	set_cell(LAYER_SELECT, selected_tile, SOURCE_SELECT, Vector2i(0, 0))


func set_reachables(_reachables):
	hide_reachables()
	reachables = _reachables


func show_reachables():
	for reachable_tile in reachables:
		set_cell(LAYER_HIGHLIGHT, reachable_tile, SOURCE_HIGHLIGHT, HIGHLIGHT_GREEN)


func hide_reachables():
	for reachable_tile in reachables:
		set_cell(LAYER_HIGHLIGHT, reachable_tile, -1, Vector2i(-1, -1))


func set_movement_path(_movement_path, _not_enough_ap):
	hide_movement_path()
	movement_path = _movement_path
	not_enough_ap = _not_enough_ap


func show_movement_path():
	for tile in movement_path:
		set_cell(LAYER_HIGHLIGHT_SELECT, tile, SOURCE_HIGHLIGHT_SELECT, HIGHLIGHT_SELECT_RED if not_enough_ap else HIGHLIGHT_SELECT_LIGHTBLUE)


func hide_movement_path():
	for tile in movement_path:
		set_cell(LAYER_HIGHLIGHT_SELECT, tile, -1, Vector2i(-1, -1))


func set_attackables(_attackables):
	hide_attackables()
	attackables = _attackables


func show_attackables():
	for attackable_tile in attackables.keys():
		var ranged_acc_mod = attackables[attackable_tile]
		set_cell(LAYER_HIGHLIGHT, attackable_tile, SOURCE_HIGHLIGHT, HIGHLIGHT_RED if ranged_acc_mod < 1.0 else
			(HIGHLIGHT_YELLOW if ranged_acc_mod == 1.0 else HIGHLIGHT_GREEN))


func hide_attackables():
	for attackable_tile in attackables.keys():
		set_cell(LAYER_HIGHLIGHT, attackable_tile, -1, Vector2i(-1, -1))


func set_attack_target(_attack_target, _not_enough_ap):
	hide_attack_target()
	attack_targets = _attack_target
	not_enough_ap = _not_enough_ap


func show_attack_target():
	for attack_target in attack_targets:
		set_cell(LAYER_HIGHLIGHT_SELECT, attack_target, SOURCE_HIGHLIGHT_SELECT, HIGHLIGHT_SELECT_RED if not_enough_ap else HIGHLIGHT_SELECT_WHITE)


func hide_attack_target():
	for attack_target in attack_targets:
		set_cell(LAYER_HIGHLIGHT_SELECT, attack_target, -1, Vector2i(-1, -1))
