extends Node

# menu ui
signal pressed_server_host(username, port)
signal pressed_server_join(username, address)
signal pressed_ready()
signal pressed_start()
signal pressed_disconnect()
signal sent_feedback(message)
signal server_sent_chat_message(message, color)
signal client_sent_chat_message(message)

signal player_list_updated(dict)

signal game_is_ready(map_path)


signal game_class_selected(gcid)

# game controller
signal game_input_enabled(value)

#region server events

## Fires when a GameEffect expires, after the internal expire callback
signal effect_expired(effect_id: int)

## Fires on game start
signal game_started(game_start_context: GameStartContext)
## Fires when a player takes damage
signal player_took_damage(attack_context: AttackContext)
## Fires when a player loses health
signal player_lost_health(attack_context: AttackContext)
## Fires when an effect is about to be applied to a player
signal effect_applied_to_player(applier, target, effect_class, action_results)
## Fires when an effect is applied to a player
signal effect_applied_to_player_success(applier, target, effect_instance, action_results)
## Fires when a player is healed
signal player_healed(heal_context: HealContext)
## Fires when a player's health is changed
signal player_health_changed(health_change_context: HealthChangeContext)

## Fires before everything occurs
signal movement_declared(move_context: MoveContext)
## Fires just before moving/subtracting ap
signal tile_left(move_context: MoveContext)
## Fires after moving/subtracting ap and pushing MoveResult into action results
signal tile_entered(move_context: MoveContext)
## Fires after pushing EndMoveResult into action results
signal movement_concluded(move_context: MoveContext)

## Fires before individual attacks are performed
signal attack_declared(attack_context: AttackContext)
## Fires before an attack against a single target is performed
signal attack_individual_declared(attack_context: AttackContext)
## Fires after an attack passes acc check against a single target before damage is done
signal attack_individual_hit(attack_context: AttackContext)
## Fires after an attack passes acc check against a single target after damage is done
signal attack_individual_hit_after_damage(attack_context: AttackContext)
## Fires after an attack fails acc check against a single target
signal attack_individual_missed(attack_context: AttackContext)
## Fires after an attack against a single target is performed
signal attack_individual_concluded(attack_context: AttackContext)
## Fires after everything in an attack
signal attack_concluded(attack_context: AttackContext)

signal phase_end_declared(end_phase_context: EndPhaseContext)
signal phase_end_concluded(end_phase_context: EndPhaseContext)
signal turn_ended()

#endregion

# server messages
signal action_response_received(action_response: ActionResponse)

# player info ui
signal player_info_updated(player: Player, stat_mods: TileStatBonus)
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
signal game_resolved(result, victor_name)
signal phase_display_finished()

# end turn ui
signal end_turn_prompt_ui_freed()
signal end_turn_prompt_showed(has_remaining_ap: bool)
signal end_turn_confirmed(do_not_remind: bool)
signal end_turn_canceled()

# turn timer ui
signal turn_timer_ui_freed()
signal turn_timer_refreshed()

# camera
signal camera_force_panned(pos: Vector2, duration: float)
signal camera_panned(pan_direction: Vector2)
signal camera_zoomed(direction: int)
signal camera_bounds_updated(max_x_mapgrid, min_x_mapgrid, max_y_mapgrid, min_y_mapgrid)

# player
signal player_sprite_moved(pid: int, movement_step: int)
signal player_sprite_move_finished()
signal player_sprite_ended_movement_chain(pid: int)
signal player_sprite_attacked(pid: int, target_mapgrid: Vector2i)
signal player_sprite_popup_displayed(pid: int, message: String, color: Color, is_dead: bool)
signal player_sprite_popup_finished()
signal player_sprite_attack_finished()
signal anim_is_being_played(value: bool)
signal turn_color_updated(turn_of_player)
signal tooltip_updated(pid: int, tooltip_text: String)
