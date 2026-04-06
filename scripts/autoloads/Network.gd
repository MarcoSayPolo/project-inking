extends Node

const PORT: int = 7777
var local_player_id: int = 0  # 0 = hot-seat, 1 = host/P1, 2 = client/P2
var is_host: bool = false

signal connection_succeeded
signal connection_failed
signal player_connected(id: int)
signal player_disconnected(id: int)


func host_game() -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_server(PORT, 2)
	if err != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	is_host = true
	local_player_id = 1
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func join_game(ip: String) -> void:
	var peer := ENetMultiplayerPeer.new()
	var err := peer.create_client(ip, PORT)
	if err != OK:
		connection_failed.emit()
		return
	multiplayer.multiplayer_peer = peer
	is_host = false
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func disconnect_game() -> void:
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
	is_host = false
	local_player_id = 0


func _on_connected_to_server() -> void:
	local_player_id = 2
	connection_succeeded.emit()


func _on_connection_failed() -> void:
	connection_failed.emit()


func _on_peer_connected(id: int) -> void:
	player_connected.emit(id)


func _on_peer_disconnected(id: int) -> void:
	player_disconnected.emit(id)
