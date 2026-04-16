extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

@onready var ip_input = $VBoxContainer/HBoxJoin/IPAddress

func _on_host_pressed() -> void:
	MultiplayerManager.host_game()
	get_tree().change_scene_to_file("res://Scenes/Levels/Lobby.tscn")

func _on_join_pressed() -> void:
	MultiplayerManager.join_game(ip_input.text)
	get_tree().change_scene_to_file("res://Scenes/Levels/Lobby.tscn")



func _on_options_pressed() -> void:
	pass # Replace with function body.


func _on_exit_pressed() -> void:
	get_tree().quit()
