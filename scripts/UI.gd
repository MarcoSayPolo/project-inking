extends CanvasLayer

@onready var turn_label: Label = $Panel/VBox/TurnLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var status_label: Label = $Panel/VBox/StatusLabel
@onready var winner_panel: Panel = $WinnerPanel
@onready var winner_label: Label = $WinnerPanel/VBox/WinnerLabel
@onready var restart_button: Button = $WinnerPanel/VBox/RestartButton


func _ready() -> void:
	GameState.turn_changed.connect(_on_turn_changed)
	GameState.board_changed.connect(_on_board_changed)
	restart_button.pressed.connect(_on_restart)
	winner_panel.visible = false
	_on_turn_changed(GameState.current_turn)


func _on_turn_changed(player_id: int) -> void:
	turn_label.text = "Player %d's Turn" % player_id
	_on_board_changed()


func _on_board_changed() -> void:
	score_label.text = "P1: %d    P2: %d" % [GameState.scores[1], GameState.scores[2]]
	var turns_left := GameState.MAX_TURNS - GameState.turn_number
	status_label.text = "Turns left: %d" % turns_left


func show_winner(winner: int) -> void:
	winner_panel.visible = true
	if winner == 0:
		winner_label.text = "It's a Tie!"
	else:
		winner_label.text = "Player %d Wins!\nP1: %d  P2: %d" % [
			winner, GameState.scores[1], GameState.scores[2]
		]
	restart_button.text = "Back to Lobby" if Network.local_player_id != 0 else "Play Again"


func show_disconnected() -> void:
	winner_panel.visible = true
	winner_label.text = "Opponent disconnected."
	restart_button.text = "Back to Lobby"


func _on_restart() -> void:
	winner_panel.visible = false
	if Network.local_player_id != 0:
		# Networked: disconnect and return to lobby
		Network.disconnect_game()
		get_tree().change_scene_to_file("res://scenes/Lobby.tscn")
	else:
		# Hot-seat: just reset
		GameState.reset()
		GameState.board_changed.emit()
		GameState.turn_changed.emit(GameState.current_turn)
