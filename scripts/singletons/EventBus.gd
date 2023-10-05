extends Node

signal pressed_server_host(username, port)
signal pressed_server_join(username, address)
signal pressed_ready()
signal pressed_start()
signal pressed_disconnect()
signal sent_feedback(message)

signal player_list_updated(dict)

signal game_is_ready(map_path)
signal game_tile_hovered(atlas_texture, atlas_coord, name, description)