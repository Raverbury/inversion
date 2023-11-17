extends Node

# menu ui
signal pressed_server_host(username, port)
signal pressed_server_join(username, address)
signal pressed_ready()
signal pressed_start()
signal pressed_disconnect()
signal sent_feedback(message)
signal sent_chat_message(message)
signal chat_message_sent(text)

signal player_list_updated(dict)

signal game_is_ready(map_path)


signal game_class_selected(gcid)

signal game_started(game_state: GameState)

# player info ui
signal player_info_updated(player: Player, stat_mods: Dictionary)
signal ap_cost_updated(path_cost: int)
signal player_info_ui_freed()

# tile info ui
signal game_tile_hovered(atlas_texture, atlas_coord, name, description, ap_cost, acc_mod, eva_mod, armor_mod)
signal tile_info_ui_freed()

# class select ui
signal class_select_ui_freed()

# turn ui
signal turn_ui_freed()
signal turn_displayed(player_name: String, is_me: bool, turn: int)

# camera
signal camera_panned(pos: Vector2, duration: float)

# player
signal player_moved(pid: int, movement_steps: Array)
