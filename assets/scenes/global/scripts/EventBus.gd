extends Node

signal pressed_server_host(username, port)
signal pressed_server_join(username, address)
signal pressed_ready()
signal pressed_start()
signal pressed_disconnect()
signal sent_feedback(message)

signal player_list_updated(dict)

signal game_is_ready(map_path)


signal game_class_selected(gcid)

signal game_started(game_state: GameState)

# tile info ui
signal game_tile_hovered(atlas_texture, atlas_coord, name, description)
signal tile_info_ui_freed()

# class select ui
signal class_select_ui_freed()

# camera
signal camera_panned(pos: Vector2, duration: float)

# player
signal player_moved(pid: int, movement_steps: Array)