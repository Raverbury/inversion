extends Panel

@onready var tile_image_trect: TextureRect = $TileImage
@onready var tile_name_label: Label = $TileName
@onready var tile_description_label: Label = $TileDescription

func _ready():
	EventBus.game_tile_hovered.connect(__on_tile_hovered)
	EventBus.tile_info_ui_freed.connect(__on_tile_info_freed)


func __on_tile_hovered(atlas_texture, atlas_coord, tile_name, tile_description):
	tile_image_trect.texture.atlas = atlas_texture
	tile_image_trect.texture.region.position = atlas_coord * 32
	tile_name_label.text = tile_name
	tile_description_label.text = tile_description


func __on_tile_info_freed():
	queue_free()