extends Panel

@onready var tile_image_trect: TextureRect = $TileImage
@onready var tile_name_label: Label = $TileName
@onready var tile_description_label: Label = $TileDescription
@onready var ap_cost_label: Label = $APCost
@onready var acc_mod_label: Label = $AccMod
@onready var eva_mod_label: Label = $EvaMod
@onready var armor_mod_label: Label = $ArmorMod

func _ready():
	EventBus.game_tile_hovered.connect(__on_tile_hovered)
	EventBus.tile_info_ui_freed.connect(__on_tile_info_freed)


func __on_tile_hovered(atlas_texture, atlas_coord, tile_name, tile_description, ap_cost, acc_mod, eva_mod, armod_mod):
	tile_image_trect.texture.atlas = atlas_texture
	tile_image_trect.texture.region.position = atlas_coord * 32
	tile_name_label.text = tile_name
	tile_description_label.text = tile_description
	ap_cost_label.text = "AP cost: %s" % (ap_cost if ap_cost != -1 else "-----")
	acc_mod_label.text = "ACC: %s" % (("+%s" % acc_mod) if acc_mod >= 0 else acc_mod)
	eva_mod_label.text = "EVA: %s" % (("+%s" % eva_mod) if eva_mod >= 0 else eva_mod)
	armor_mod_label.text = "Armor: %s" % (("+%s" % armod_mod) if armod_mod >= 0 else armod_mod)


func __on_tile_info_freed():
	queue_free()
