extends Node

const GRID_SIZE: int = 60
const MAX_SHOOT_RANGE: int = 30
const MAX_TURNS: int = 120  # 60 per player

var board: Array = []
var current_turn: int = 1  # 1 or 2
var turn_number: int = 0
var scores: Dictionary = {1: 0, 2: 0}
var game_over: bool = false

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

	@warning_ignore("integer_division")
	var mid: int = GRID_SIZE / 2
	# Give each player a 3-tile vertical cluster away from the edges
	for dy in [-1, 0, 1]:
		set_tile(8, mid + dy, 1)
		set_tile(GRID_SIZE - 9, mid + dy, 2)
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


# Returns ordered list of grid tiles the shot will pass through.
# direction is a normalized Vector2; shoot_range is number of steps.
func get_trajectory(origin: Vector2i, direction: Vector2, shoot_range: int) -> Array:
	var tiles: Array = []
	var seen: Dictionary = {}
	var origin_center := Vector2(origin.x + 0.5, origin.y + 0.5)
	var dir_norm := direction.normalized()

	for i in range(1, shoot_range + 1):
		var pos := origin_center + dir_norm * i
		var tile := Vector2i(int(pos.x), int(pos.y))
		if not is_in_bounds(tile.x, tile.y):
			break
		var key := tile.x * 10000 + tile.y
		if not seen.has(key):
			seen[key] = true
			tiles.append(tile)

	return tiles


func apply_move(origin: Vector2i, direction: Vector2, shoot_range: int, player_id: int) -> void:
	var trajectory := get_trajectory(origin, direction, shoot_range)
	for tile: Vector2i in trajectory:
		set_tile(tile.x, tile.y, player_id)

	recalculate_scores()
	turn_number += 1
	current_turn = 2 if current_turn == 1 else 1
	board_changed.emit()
	turn_changed.emit(current_turn)

	var winner := check_game_over()
	if winner >= 0:
		game_ended.emit(winner)


func check_game_over() -> int:
	# Returns winning player id, 0 for tie, -1 if not over yet
	if game_over:
		return _determine_winner()
	if board.count(0) == 0 or turn_number >= MAX_TURNS:
		game_over = true
		return _determine_winner()
	return -1


func _determine_winner() -> int:
	if scores[1] > scores[2]:
		return 1
	elif scores[2] > scores[1]:
		return 2
	else:
		return 0


func serialize_board() -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(board.size())
	for i in board.size():
		bytes[i] = board[i]
	return bytes


func deserialize_board(bytes: PackedByteArray) -> void:
	for i in bytes.size():
		board[i] = bytes[i]
