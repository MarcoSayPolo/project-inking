extends Node2D

const TILE_SIZE: int = 10
const TILE_DRAW_SIZE: int = 9  # 1px gap between tiles
const MAX_DRAG_PIXELS: float = 200.0

const COLORS: Array = [
	Color(0.13, 0.13, 0.13),   # 0 neutral
	Color(0.20, 0.50, 1.00),   # 1 player 1 - blue
	Color(1.00, 0.30, 0.20),   # 2 player 2 - red
]
const COLOR_ORIGIN    := Color(1.00, 1.00, 0.00, 0.85)
const COLOR_AIM_LINE  := Color(1.00, 1.00, 1.00, 0.90)
const COLOR_AIM_END   := Color(1.00, 1.00, 1.00, 0.95)
const COLOR_TILE_HIT  := Color(1.00, 1.00, 1.00, 0.18)

var _local_player_id: int = 1

var _dragging: bool = false
var _drag_origin: Vector2i = Vector2i(-1, -1)
var _drag_current: Vector2 = Vector2.ZERO


func _ready() -> void:
	GameState.board_changed.connect(queue_redraw)


func set_local_player(id: int) -> void:
	_local_player_id = id


# ── Input ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if GameState.game_over:
		return

	var is_networked := multiplayer.multiplayer_peer != null and Network.local_player_id != 0
	if is_networked and GameState.current_turn != Network.local_player_id:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_try_start_drag(get_local_mouse_position())
		else:
			_try_release_drag()
	elif event is InputEventMouseMotion and _dragging:
		_drag_current = get_local_mouse_position()
		queue_redraw()


func _try_start_drag(local_pos: Vector2) -> void:
	var tile := _pos_to_tile(local_pos)
	if not GameState.is_in_bounds(tile.x, tile.y):
		return
	if GameState.get_tile(tile.x, tile.y) != GameState.current_turn:
		return
	_dragging = true
	_drag_origin = tile
	_drag_current = local_pos
	queue_redraw()


func _try_release_drag() -> void:
	if not _dragging:
		return
	_dragging = false

	var origin_center := _tile_center(_drag_origin)
	var drag_vec := _drag_current - origin_center

	if drag_vec.length() < TILE_SIZE:
		_drag_origin = Vector2i(-1, -1)
		queue_redraw()
		return

	# Pull back = shoot forward (slingshot)
	var direction := -drag_vec.normalized()
	var shoot_range := int(clamp(
		drag_vec.length() / MAX_DRAG_PIXELS * GameState.MAX_SHOOT_RANGE,
		1.0, float(GameState.MAX_SHOOT_RANGE)
	))

	var origin := _drag_origin
	_drag_origin = Vector2i(-1, -1)
	queue_redraw()

	get_parent().on_local_move(origin, direction, shoot_range)


# ── Helpers ──────────────────────────────────────────────────────────────────

func _pos_to_tile(pos: Vector2) -> Vector2i:
	return Vector2i(int(pos.x / TILE_SIZE), int(pos.y / TILE_SIZE))


func _tile_center(tile: Vector2i) -> Vector2:
	return (Vector2(tile) + Vector2(0.5, 0.5)) * TILE_SIZE


# ── Drawing ──────────────────────────────────────────────────────────────────

func _draw() -> void:
	var draw_sz := Vector2(TILE_DRAW_SIZE, TILE_DRAW_SIZE)

	for y in GameState.GRID_SIZE:
		for x in GameState.GRID_SIZE:
			var owner_id: int = GameState.board[GameState.coords_to_index(x, y)]
			draw_rect(
				Rect2(Vector2(x * TILE_SIZE, y * TILE_SIZE), draw_sz),
				COLORS[owner_id]
			)

	if _dragging and _drag_origin != Vector2i(-1, -1):
		_draw_drag_preview(draw_sz)


func _draw_drag_preview(draw_sz: Vector2) -> void:
	var origin_center := _tile_center(_drag_origin)
	var drag_vec := _drag_current - origin_center
	var drag_len := drag_vec.length()

	# Always highlight the origin tile
	draw_rect(Rect2(Vector2(_drag_origin) * TILE_SIZE, draw_sz), COLOR_ORIGIN)

	if drag_len < TILE_SIZE:
		return

	# Pull back = shoot forward (slingshot)
	var direction := -drag_vec.normalized()
	var shoot_range := int(clamp(
		drag_len / MAX_DRAG_PIXELS * GameState.MAX_SHOOT_RANGE,
		1.0, float(GameState.MAX_SHOOT_RANGE)
	))

	var trajectory := GameState.get_trajectory(_drag_origin, direction, shoot_range)
	if trajectory.is_empty():
		return

	var last_tile: Vector2i = trajectory[-1]
	var end_center := _tile_center(last_tile)

	# Subtle tile tint so you can see what will be painted
	for tile: Vector2i in trajectory:
		draw_rect(Rect2(Vector2(tile) * TILE_SIZE, draw_sz), COLOR_TILE_HIT)

	# Solid line toward cursor = the pull-back
	draw_line(origin_center, _drag_current, COLOR_AIM_LINE * Color(1, 1, 1, 0.5), 1.5)

	# Dashed line in opposite direction = the shot trajectory
	draw_dashed_line(origin_center, end_center, COLOR_AIM_LINE, 1.5, 6.0, true)

	# Filled circle at the landing spot
	draw_circle(end_center, 3.5, COLOR_AIM_END)

	# Power label: show range number above the origin
	var label_pos := Vector2(_drag_origin) * TILE_SIZE + Vector2(TILE_SIZE * 0.5, -10)
	draw_string(
		ThemeDB.fallback_font,
		label_pos,
		str(shoot_range),
		HORIZONTAL_ALIGNMENT_CENTER,
		-1,
		10,
		COLOR_AIM_END
	)
