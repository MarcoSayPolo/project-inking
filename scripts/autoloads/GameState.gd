extends Node

const GRID_SIZE: int = 20
const SHOOT_RANGE: int = 5
const MAX_TURNS: int = 60  # 30 per player

var board: Array = []
var current_turn: int = 1  # 1 or 2
var turn_number: int = 0
var scores: Dictionary = {1: 0, 2: 0}
var game_over: bool = false

# Local input state (not synced over network)
var selected_origin: Vector2i = Vector2i(-1, -1)
var input_phase: int = 0  # 0 = select origin, 1 = select direction

signal board_changed
signal turn_changed(player_id: int)
signal game_ended(winner: int)


func _ready() -> void:
	reset()


func reset() -> void:
	board.clear()
	board.resize(GRID_SIZE * GRID_SIZE)
	board.fill(0)
	current_turn = 1
	turn_number = 0
	scores = {1: 0, 2: 0}
	game_over = false
	selected_origin = Vector2i(-1, -1)
	input_phase = 0

	# Place starting tiles
	@warning_ignore("integer_division")
	var mid: int = GRID_SIZE / 2
	set_tile(0, mid, 1)
	set_tile(GRID_SIZE - 1, mid, 2)
	recalculate_scores()


func coords_to_index(x: int, y: int) -> int:
	return y * GRID_SIZE + x


func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < GRID_SIZE and y >= 0 and y < GRID_SIZE


func get_tile(x: int, y: int) -> int:
	if not is_in_bounds(x, y):
		return -1
	return board[coords_to_index(x, y)]


func set_tile(x: int, y: int, owner_id: int) -> void:
	if is_in_bounds(x, y):
		board[coords_to_index(x, y)] = owner_id


func recalculate_scores() -> void:
	scores[1] = board.count(1)
	scores[2] = board.count(2)


# Apply a validated move: walk tiles, advance turn, emit signals
func apply_move(origin: Vector2i, direction: Vector2i, player_id: int) -> void:
	for i in range(1, SHOOT_RANGE + 1):
		var tx := origin.x + direction.x * i
		var ty := origin.y + direction.y * i
		if not is_in_bounds(tx, ty):
			break
		set_tile(tx, ty, player_id)

	recalculate_scores()
	turn_number += 1
	current_turn = 2 if current_turn == 1 else 1
	board_changed.emit()
	turn_changed.emit(current_turn)

	var winner := check_game_over()
	if winner >= 0:
		game_ended.emit(winner)


func check_game_over() -> int:
	# Returns winning player id, 0 for tie, -1 if not over
	if game_over:
		return _determine_winner()
	var neutral_count: int = board.count(0)
	if neutral_count == 0 or turn_number >= MAX_TURNS:
		game_over = true
		return _determine_winner()
	return -1


func _determine_winner() -> int:
	if scores[1] > scores[2]:
		return 1
	elif scores[2] > scores[1]:
		return 2
	else:
		return 0  # tie


func serialize_board() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(board.size())
	for i in board.size():
		bytes[i] = board[i]
	return bytes


func deserialize_board(bytes: PackedByteArray) -> void:
	for i in bytes.size():
		board[i] = bytes[i]
