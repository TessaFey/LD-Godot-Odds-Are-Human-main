extends Node3D

@onready var portal_area = $PortalArea
@onready var countdown_label = $CanvasLayer/CountdownLabel

var counting_down = false
var countdown = 5.0

func _ready() -> void:
	countdown_label.visible = false
	portal_area.body_entered.connect(_on_enter)
	portal_area.body_exited.connect(_on_exit)

func _process(delta: float) -> void:
	if counting_down:
		countdown -= delta
		countdown_label.text = "Starting in " + str(int(ceil(countdown)))

		if countdown <= 0:
			get_tree().change_scene_to_file("res://level_1.tscn")

func _on_enter(body: Node) -> void:
	if body.name == "Steve":
		counting_down = true
		countdown = 5.0
		countdown_label.visible = true
		countdown_label.text = "Starting in 5"

func _on_exit(body: Node) -> void:
	if body.name == "Steve":
		counting_down = false
		countdown = 5.0
		countdown_label.visible = false
