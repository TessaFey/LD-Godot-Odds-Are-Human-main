extends Area3D

const ROT_SPEED := 169.0

@onready var sfx: AudioStreamPlayer3D = $AudioStreamPlayer3D
var collected := false

func _process(delta):
	rotate_y(deg_to_rad(ROT_SPEED) * delta)

func _on_body_entered(body: Node3D) -> void:
	if collected:
		return

	if body.is_in_group("player"):
		collected = true

		monitoring = false
		visible = false

		GameManager.add_coin()

		sfx.play()
		await sfx.finished

		queue_free()
