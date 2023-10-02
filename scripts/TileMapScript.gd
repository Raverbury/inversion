extends TileMap


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _input(event):
	if event is InputEventMouseButton:
		var clicked_cell = local_to_map(get_global_mouse_position())
		print(clicked_cell)
		var tile_data: TileData = get_cell_tile_data(0, clicked_cell)
		if tile_data != null:
			print(tile_data.get_custom_data("ap_cost"))
