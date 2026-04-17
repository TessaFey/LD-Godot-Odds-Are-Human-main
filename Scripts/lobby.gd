extends Node3D

@onready var portal_area = $PortalArea
@onready var countdown_label = $CanvasLayer/CountdownLabel
@onready var players_node = $Players
var steve_scene = preload("res://steve.tscn")

var counting_down = false
var countdown = 2.0

func _ready() -> void:
	countdown_label.visible = false
	portal_area.body_entered.connect(_on_enter)
	portal_area.body_exited.connect(_on_exit)
	
	if multiplayer.is_server():
		for peer_id in MultiplayerManager.players:
			var player = steve_scene.instantiate()
			player.name = str(peer_id)
			player.position = Vector3(0, 5, 0)
			players_node.add_child(player)

func _process(delta: float) -> void:
	if counting_down:
		countdown -= delta
		countdown_label.text = "Starting in " + str(int(ceil(countdown)))

		if countdown <= 0:
			MultiplayerManager.server_change_scene("res://level_1.tscn")

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		counting_down = true
		countdown = 2.0
		countdown_label.visible = true
		countdown_label.text = "Starting in 2 seconds..."

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		counting_down = false
		countdown = 2.0
		countdown_label.visible = false
