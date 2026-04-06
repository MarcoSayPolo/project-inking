extends Control

@onready var local_button: Button = $VBox/LocalButton
@onready var host_button: Button = $VBox/HostButton
@onready var ip_input: LineEdit = $VBox/IPInput
@onready var join_button: Button = $VBox/JoinButton
@onready var status_label: Label = $VBox/StatusLabel


func _ready() -> void:
	local_button.pressed.connect(_on_local_pressed)
	host_button.pressed.connect(_on_host_pressed)
	join_button.pressed.connect(_on_join_pressed)
	Network.connection_succeeded.connect(_on_connected)
	Network.connection_failed.connect(_on_connection_failed)
	Network.player_connected.connect(_on_player_connected)
	ip_input.placeholder_text = "Enter host IP (e.g. 127.0.0.1)"


func _on_local_pressed() -> void:
	Network.local_player_id = 0
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_host_pressed() -> void:
	status_label.text = "Hosting... waiting for player to join."
	host_button.disabled = true
	join_button.disabled = true
	Network.host_game()


func _on_join_pressed() -> void:
	var ip := ip_input.text.strip_edges()
	if ip.is_empty():
		ip = "127.0.0.1"
	status_label.text = "Connecting to %s..." % ip
	host_button.disabled = true
	join_button.disabled = true
	Network.join_game(ip)


func _on_connected() -> void:
	# Client: successfully connected to host
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_connection_failed() -> void:
	status_label.text = "Connection failed. Check the IP and try again."
	host_button.disabled = false
	join_button.disabled = false


func _on_player_connected(_id: int) -> void:
	# Host: a player joined — start the game
	if Network.is_host:
		get_tree().change_scene_to_file("res://scenes/Game.tscn")
