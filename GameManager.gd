extends Node

@export var coins: int = 0
var menu_open: bool = false

func add_coin():
	coins += 1
	print("Coins:", coins)

func set_menu_open(value: bool) -> void:
	menu_open = value
	print("Menu open:", menu_open)

func reset_player_to_spawn():
	var current_scene = get_tree().current_scene
	var player = get_tree().get_first_node_in_group("player")
	var spawn = get_tree().get_first_node_in_group("spawn_point")

	if spawn == null and current_scene != null:
		spawn = current_scene.find_child("Chunk1Spawn", true, false)

	print("Player found:", player)
	print("Spawn found:", spawn)

	if player == null:
		push_warning("No player found in group 'player'")
		return

	if spawn == null:
		push_warning("No spawn point found in group 'spawn_point' and no Chunk1Spawn node found")
		return

	if player is Node3D and spawn is Node3D:
		player.global_position = spawn.global_position
		player.global_rotation = spawn.global_rotation

	if player is CharacterBody3D:
		player.velocity = Vector3.ZERO
