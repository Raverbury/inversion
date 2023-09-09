extends Node

signal pressed_server_host(username, port)
signal pressed_server_join(username, address)
signal pressed_ready()
signal pressed_start()
signal pressed_disconnect()
signal sent_feedback(message)

signal player_list_updated(dict)