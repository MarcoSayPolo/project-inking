extends Node

@onready var grid = $Grid
@onready var ui = $UI


func _ready() -> void:
	GameState.reset()
	var pid := Network.local_player_id if Network.local_player_id != 0 else 1
	grid.set_local_player(pid)
	GameState.game_ended.connect(_on_game_ended)
	Network.player_disconnected.connect(_on_peer_disconnected)

	if Network.is_host:
		# Give client time to load the scene before syncing state
		await get_tree().create_timer(0.5).timeout
		sync_initial_state.rpc(
			GameState.serialize_board(),
			GameState.current_turn,
			GameState.turn_number
		)

	GameState.board_changed.emit()
	GameState.turn_changed.emit(GameState.current_turn)


# Called by Grid.gd when the local player picks origin + direction
func on_local_move(origin: Vector2i, direction: Vector2i) -> void:
	var player_id := GameState.current_turn
	if GameState.get_tile(origin.x, origin.y) != player_id:
		return

	var is_networked := multiplayer.multiplayer_peer != null and Network.local_player_id != 0

	if not is_networked:
		# Hot-seat: apply directly
		GameState.apply_move(origin, direction, player_id)
	elif Network.is_host:
		# Host: apply locally then broadcast to client
		GameState.apply_move(origin, direction, player_id)
		apply_move_rpc.rpc(
			GameState.serialize_board(),
			GameState.current_turn,
			GameState.turn_number
		)
	else:
		# Client: ask host to validate and apply
		request_move.rpc_id(1, origin, direction)


@rpc("any_peer", "call_remote", "reliable")
func request_move(origin: Vector2i, direction: Vector2i) -> void:
	if not Network.is_host:
		return
	# Client is always P2
	if GameState.current_turn != 2:
		return
	if GameState.get_tile(origin.x, origin.y) != 2:
		return
	GameState.apply_move(origin, direction, 2)
	apply_move_rpc.rpc(
		GameState.serialize_board(),
		GameState.current_turn,
		GameState.turn_number
	)


@rpc("authority", "call_remote", "reliable")
func apply_move_rpc(board_bytes: PackedByteArray, next_turn: int, turn_num: int) -> void:
	# Runs on client only — sync state from host
	GameState.deserialize_board(board_bytes)
	GameState.current_turn = next_turn
	GameState.turn_number = turn_num
	GameState.recalculate_scores()
	GameState.board_changed.emit()
	GameState.turn_changed.emit(next_turn)
	var winner := GameState.check_game_over()
	if winner >= 0:
		GameState.game_ended.emit(winner)


@rpc("authority", "call_remote", "reliable")
func sync_initial_state(board_bytes: PackedByteArray, turn: int, turn_num: int) -> void:
	GameState.deserialize_board(board_bytes)
	GameState.current_turn = turn
	GameState.turn_number = turn_num
	GameState.recalculate_scores()
	GameState.board_changed.emit()
	GameState.turn_changed.emit(turn)


func _on_game_ended(winner: int) -> void:
	ui.show_winner(winner)


func _on_peer_disconnected(_id: int) -> void:
	ui.show_disconnected()
