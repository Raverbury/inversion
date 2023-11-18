extends Node


@rpc("any_peer", "call_local", "reliable", 0)
func test(data):
	print(get_tree().get_multiplayer().get_remote_sender_id(), " send ", data)


@rpc("any_peer", "call_local", "reliable", 0)
func player_send_chat_message(data: Dictionary):
	var message: PlayerSendChatMessage = SRLZ.deserialize(data)
	var pid = Main.root_mp.get_remote_sender_id()
	var display_name = message.display_name.replace("[", "[lb]")
	var content = message.chat_text.replace("[", "[lb]")
	EventBus.sent_chat_message.emit("%s (%d): %s" % [display_name, pid, content])


@rpc("any_peer", "call_remote", "reliable", 0)
func player_connect(data: Dictionary):
	if Main.root_mp.is_server() == false:
		return
	var message: PlayerConnectMessage = SRLZ.deserialize(data)
	var pid = Main.root_mp.get_remote_sender_id()
	EventBus.sent_feedback.emit(str(pid) + " joined as " + message.display_name.replace("[", "[lb]"))
	Server.add_player(pid, message.display_name)


@rpc("any_peer", "call_local", "reliable", 0)
func player_set_readiness(data: Dictionary):
	if Main.root_mp.is_server() == false:
		return
	var message: PlayerSetReadinessMessage = SRLZ.deserialize(data)
	Server.player_set_ready(Main.root_mp.get_remote_sender_id(), message.readiness)


@rpc("authority", "call_local", "reliable", 0)
func update_player_list(data: Dictionary):
	var message: PlayerListUpdateMessage = SRLZ.deserialize(data)
	EventBus.player_list_updated.emit(message.player_dict)


@rpc("authority", "call_local", "reliable", 0)
func room_start(data: Dictionary):
	var message: RoomStartMessage = SRLZ.deserialize(data)
	EventBus.game_is_ready.emit(message.map_path)


@rpc("any_peer", "call_local", "reliable", 0)
func player_pick_class(data: Dictionary):
	var message: PlayerPickClassMessage = SRLZ.deserialize(data)
	Server.player_set_class(Main.root_mp.get_remote_sender_id(), message.class_id)


@rpc("authority", "call_local", "reliable", 0)
func game_start(data: Dictionary):
	var message: GameStartMessage = SRLZ.deserialize(data)
	EventBus.game_started.emit(message.game_state)


@rpc("any_peer", "call_local", "reliable", 0)
func player_request_move(data: Dictionary):
	var message: PlayerMoveRequestMessage = SRLZ.deserialize(data)
	Server.process_player_move_request(Main.root_mp.get_remote_sender_id(), message.move_steps)


@rpc("authority", "call_local", "reliable", 0)
func player_move_update(data: Dictionary):
	var message: PlayerMoveResponseMessage = SRLZ.deserialize(data)
	EventBus.player_move_updated.emit(message.player_id, message.move_steps, message.game_state)


@rpc("any_peer", "call_local", "reliable", 0)
func player_request_attack(data: Dictionary):
	var message: PlayerAttackRequestMessage = SRLZ.deserialize(data)
	Server.process_player_attack_request(Main.root_mp.get_remote_sender_id(), message.target_mapgrid)


@rpc("authority", "call_local", "reliable", 0)
func player_attack_update(data: Dictionary):
	var message: PlayerAttackResponseMessage = SRLZ.deserialize(data)
	EventBus.player_attack_updated.emit(message.attacker_id, message.target_mapgrid, message.victims, message.game_state)
