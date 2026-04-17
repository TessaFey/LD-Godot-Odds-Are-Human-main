extends Control

@onready var start_button: Button = $VBoxContainer/Start
@onready var options_button: Button = $VBoxContainer/Options
@onready var exit_button: Button = $VBoxContainer/Exit

var buttons: Array[Button] = []
var current_index: int = 0
var using_keyboard := false
var is_pressing := false

var stick_deadzone := 0.5
var stick_ready := true

var original_normal_styles: Dictionary = {}
var hover_styles: Dictionary = {}
var pressed_styles: Dictionary = {}


func _ready() -> void:
	print("MAIN MENU LOADED")

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	using_keyboard = false

	buttons = [start_button, options_button, exit_button]

	for i in range(buttons.size()):
		var button := buttons[i]

		if button == null:
			push_error("A button path is wrong in main_menu.gd")
			continue

		button.focus_mode = Control.FOCUS_NONE
		button.mouse_entered.connect(_on_button_mouse_entered.bind(i))

		original_normal_styles[button] = button.get_theme_stylebox("normal")
		hover_styles[button] = button.get_theme_stylebox("hover")
		pressed_styles[button] = button.get_theme_stylebox("pressed")

	_apply_all_normal_styles()
	_set_current_button(0)

	print("Controllers connected: ", Input.get_connected_joypads())


func _input(event: InputEvent) -> void:
	# =========================
	# MOUSE
	# =========================
	if event is InputEventMouseMotion:
		if using_keyboard:
			_use_mouse_input()
		return

	# =========================
	# KEYBOARD
	# =========================
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			_use_keyboard_input()
			_move_selection(-1)
			return

		if event.keycode == KEY_S or event.keycode == KEY_DOWN:
			_use_keyboard_input()
			_move_selection(1)
			return

		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_use_keyboard_input()
			_press_current_button()
			return

		# Debug controller simulation
		if event.keycode == KEY_I:
			print("DEBUG: DPAD UP")
			_use_keyboard_input()
			_move_selection(-1)
			return

		if event.keycode == KEY_K:
			print("DEBUG: DPAD DOWN")
			_use_keyboard_input()
			_move_selection(1)
			return

		if event.keycode == KEY_J:
			print("DEBUG: A BUTTON / CONFIRM")
			_use_keyboard_input()
			_press_current_button()
			return

	# =========================
	# CONTROLLER BUTTONS
	# =========================
	if event is InputEventJoypadButton and event.pressed:
		_use_keyboard_input()

		print("Controller button: ", event.button_index)

		if event.button_index == JOY_BUTTON_DPAD_UP:
			_move_selection(-1)
			return

		if event.button_index == JOY_BUTTON_DPAD_DOWN:
			_move_selection(1)
			return

		if event.button_index == 0:
			_press_current_button()
			return

	# =========================
	# CONTROLLER STICK
	# =========================
	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		_use_keyboard_input()

		print("Stick Y: ", event.axis_value)

		if stick_ready:
			if event.axis_value > stick_deadzone:
				stick_ready = false
				_move_selection(1)
				return
			elif event.axis_value < -stick_deadzone:
				stick_ready = false
				_move_selection(-1)
				return
		else:
			if abs(event.axis_value) < 0.2:
				stick_ready = true


func _use_keyboard_input() -> void:
	using_keyboard = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_refresh_button_styles()


func _use_mouse_input() -> void:
	using_keyboard = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_apply_all_normal_styles()


# =========================
# MENU LOGIC
# =========================

func _move_selection(direction: int) -> void:
	if is_pressing:
		return

@onready var ip_input = $VBoxContainer/HBoxJoin/IPAddress

func _on_host_pressed() -> void:
	MultiplayerManager.host_game()
	get_tree().change_scene_to_file("res://Scenes/Levels/Lobby.tscn")

func _on_join_pressed() -> void:
	MultiplayerManager.join_game(ip_input.text)
	get_tree().change_scene_to_file("res://Scenes/Levels/Lobby.tscn")


func _on_options_pressed() -> void:
	print("OPTIONS")


func _on_exit_pressed() -> void:
	print("EXIT")
	get_tree().quit()
