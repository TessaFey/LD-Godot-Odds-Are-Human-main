extends Node3D

@export var possible_chunks: Array[PackedScene] = []
@onready var chunk_spawn: Marker3D = $Chunk3Spawn

func _ready():
	call_deferred("spawn_random_chunk")

func spawn_random_chunk():
	if possible_chunks.is_empty():
		push_error("No chunks assigned to possible_chunks.")
		return

	if chunk_spawn == null:
		push_error("Chunk3Spawn marker not found.")
		return

	var chosen_chunk: PackedScene = possible_chunks[randi() % possible_chunks.size()]
	var chunk = chosen_chunk.instantiate()

	add_child(chunk)
	chunk.global_transform = chunk_spawn.global_transform
	print("Spawned chunk at: ", chunk.global_position)
