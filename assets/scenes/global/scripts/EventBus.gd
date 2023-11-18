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

# game controller
signal game_input_enabled(value)

# server messages
signal game_started(game_state: GameState)
signal player_move_updated(pid, move_steps, game_state)
signal player_attack_updated(pid, target_mapgrid, victims, game_state)

# player info ui
signal player_info_updated(player: Player, stat_mods: Dictionary)
signal ap_cost_updated(path_cost: int)
signal mode_updated(mode_enum: int)
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
signal player_attacked(pid: int, target_mapgrid: Vector2i)
signal player_was_attacked(pid: int, hit: bool, damage_taken: int)
signal attack_anim_finished()
