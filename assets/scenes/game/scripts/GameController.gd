extends Node2D

var tile_map: TileMap = null
var last_cell: Vector2i
var has_last_cell: bool = false

func _ready():
	load_map("res://assets/scenes/game/map_0.tscn")

func load_map(scene_path):
	var map_tres = load(scene_path) as PackedScene
	var tile_map_scene = map_tres.instantiate()
	tile_map = tile_map_scene
	add_child(tile_map)
	move_child(tile_map, 0)

func _input(event):
	if tile_map == null:
		return
	if event is InputEventMouseMotion:
		# get tm coord/"index" of tile
		var clicked_cell: Vector2i = tile_map.local_to_map(get_global_mouse_position())
		# get source id in tileset of said tile
		var tile_id: int = tile_map.get_cell_source_id(0, clicked_cell)
		# if not empty
		if tile_id != -1:
			# grab td of source 0 first since we will switch source to 1 in a sec
			var tile_data_0: TileData = tile_map.get_cell_tile_data(0, clicked_cell)
			tile_map.set_cell(0, clicked_cell, 1, tile_map.get_cell_atlas_coords(0, clicked_cell))
			# when mouse leave tile basically
			# undo color, switch back to source 0
			if has_last_cell == true && clicked_cell != last_cell:
				var last_tile_data: TileData = tile_map.get_cell_tile_data(0, last_cell)
				last_tile_data.modulate = Color.WHITE
				tile_map.set_cell(0, last_cell, 0, tile_map.get_cell_atlas_coords(0, last_cell))
			# to prevent updating ui with info from source 1 which should be empty
			if tile_id == 1:
				return
			# save current cell info to check against when "leaving"
			last_cell = clicked_cell
			has_last_cell = true
			# swap color of source 1
			var tile_data_1: TileData = tile_map.get_cell_tile_data(0, clicked_cell)
			tile_data_1.modulate = Color.LIGHT_BLUE
			# send info of source 0 to ui
			var texture = tile_map.tile_set.get_source(0).texture
			var atlas_coord = tile_map.get_cell_atlas_coords(0, clicked_cell) as Vector2
			var tile_name = tile_data_0.get_custom_data("name")
			var tile_desc = tile_data_0.get_custom_data("description")
			EventBus.game_tile_hovered.emit(texture, atlas_coord, tile_name, tile_desc)
