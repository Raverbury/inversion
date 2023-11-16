class_name GameTileMap extends TileMap

@export var map_name: String
@export var spawn_points: Array[Vector2i]
var turn: int = 0


func get_data_at(mapgrid: Vector2, data_name: String, fallback_value):
	var tile_data: TileData = get_cell_tile_data(0, mapgrid)
	return tile_data.get_custom_data(data_name) if not tile_data == null else fallback_value

func get_ap_cost_at(mapgrid: Vector2, fallback_value = -1):
	return get_data_at(mapgrid, "ap_cost", fallback_value)
