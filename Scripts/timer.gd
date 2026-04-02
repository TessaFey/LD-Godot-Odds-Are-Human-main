extends Timer

@onready var time_label: Label = $"../CanvasLayer/MarginContainer/TimeLabel"

var countdown_seconds: int = 15
var is_blinking: bool = false
var blink_visible: bool = true

func _ready() -> void:
	timeout.connect(_on_timeout)
	update_timer_label()
	start()

func _on_timeout() -> void:
	countdown_seconds -= 1

	if countdown_seconds <= 10:
		time_label.modulate = Color.RED
		start_blinking()
	else:
		time_label.modulate = Color.WHITE

	if countdown_seconds <= 0:
		countdown_seconds = 0
		stop()
		time_label.visible = true
		update_timer_label()
		game_over()
		return

	update_timer_label()

func start_blinking() -> void:
	if is_blinking:
		return

	is_blinking = true
	blink.call_deferred()

func blink() -> void:
	while countdown_seconds > 0:
		blink_visible = !blink_visible
		time_label.visible = blink_visible
		await get_tree().create_timer(0.3).timeout

func update_timer_label() -> void:
	var minutes: int = countdown_seconds / 60
	var seconds: int = countdown_seconds % 60
	time_label.text = "%02d:%02d" % [minutes, seconds]

func game_over() -> void:
	print("Time's up!")
