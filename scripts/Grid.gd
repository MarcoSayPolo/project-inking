extends Node2D

const TILE_SIZE: int = 32
const COLORS = {
	0: Color(0.2, 0.2, 0.2),        # neutral - dark gray
	1: Color(0.2, 0.5, 1.0),        # player 1 - blue
	2: Color(1.0, 0.3, 0.2),        # player 2 - red
	"selected": Color(1.0, 1.0, 0.0, 0.5),   # yellow highlight
	"arrow": Color(1.0, 1.0, 1.0, 0.85),     # white arrows
}

const DIRECTIONS = {
	"up":    Vector2i(0, -1),
	"down":  Vector2i(0,  1),
	"left":  Vector2i(-1, 0),
	"right": Vector2i(1,  0),
}

var _tiles: Array = []         # Array of ColorRect nodes
var _arrow_buttons: Dictionary = {}  # direction -> Button node
var _local_player_id: int = 1  # set by Game.gd before game starts


func _ready() -> void:
	_build_grid()
	_build_arrows()
	GameState.board_changed.connect(_on_board_changed)


func set_local_player(id: int) -> void:
	_local_player_id = id


# ---------- Grid building ----------

func _build_grid() -> void:
	for y in GameState.GRID_SIZE:
		for x in GameState.GRID_SIZE:
			var rect := ColorRect.new()
			rect.size = Vector2(TILE_SIZE - 1, TILE_SIZE - 1)
			rect.position = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			rect.color = COLORS[0]
			add_child(rect)
			_tiles.append(rect)

			# Make each tile clickable
			rect.gui_input.connect(_on_tile_input.bind(Vector2i(x, y)))
			rect.mouse_filter = Control.MOUSE_FILTER_STOP


func _build_arrows() -> void:
	var labels = {"up": "▲", "down": "▼", "left": "◀", "right": "▶"}

	for dir_name in DIRECTIONS.keys():
		var btn := Button.new()
		btn.text = labels[dir_name]
		btn.size = Vector2(TILE_SIZE, TILE_SIZE)
		btn.visible = false
		btn.pressed.connect(_on_arrow_pressed.bind(DIRECTIONS[dir_name]))
		add_child(btn)
		_arrow_buttons[dir_name] = btn


# ---------- Input ----------

func _on_tile_input(event: InputEvent, coords: Vector2i) -> void:
	if not event is InputEventMouseButton:
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	if GameState.game_over:
		return

	# In networked play, block input when it's not our turn
	var is_networked := multiplayer.multiplayer_peer != null and Network.local_player_id != 0
	if is_networked and GameState.current_turn != Network.local_player_id:
		return

	if GameState.input_phase == 0:
		# Must click own tile to select origin
		if GameState.get_tile(coords.x, coords.y) == GameState.current_turn:
			GameState.selected_origin = coords
			GameState.input_phase = 1
			_show_arrows(coords)
			queue_redraw()


func _on_arrow_pressed(direction: Vector2i) -> void:
	_hide_arrows()
	GameState.input_phase = 0
	var origin := GameState.selected_origin
	GameState.selected_origin = Vector2i(-1, -1)
	queue_redraw()

	# Notify Game.gd to process the move
	get_parent().on_local_move(origin, direction)


# ---------- Arrow visibility ----------

func _show_arrows(origin: Vector2i) -> void:
	for dir_name in _arrow_buttons.keys():
		var btn: Button = _arrow_buttons[dir_name]
		var offset: Vector2i = DIRECTIONS[dir_name]
		var target := origin + offset
		# Only show arrow if destination is in bounds
		if GameState.is_in_bounds(target.x, target.y):
			btn.position = Vector2(
				(origin.x + offset.x) * TILE_SIZE,
				(origin.y + offset.y) * TILE_SIZE
			)
			btn.visible = true
		else:
			btn.visible = false


func _hide_arrows() -> void:
	for btn in _arrow_buttons.values():
		btn.visible = false


# ---------- Rendering ----------

func _on_board_changed() -> void:
	_redraw_tiles()
	queue_redraw()


func _redraw_tiles() -> void:
	for y in GameState.GRID_SIZE:
		for x in GameState.GRID_SIZE:
			var idx := GameState.coords_to_index(x, y)
			var owner_id: int = GameState.board[idx]
			_tiles[idx].color = COLORS[owner_id]


func _draw() -> void:
	# Highlight selected tile
	if GameState.selected_origin != Vector2i(-1, -1):
		var pos := Vector2(
			GameState.selected_origin.x * TILE_SIZE,
			GameState.selected_origin.y * TILE_SIZE
		)
		draw_rect(Rect2(pos, Vector2(TILE_SIZE - 1, TILE_SIZE - 1)), COLORS["selected"])
