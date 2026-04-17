extends CanvasLayer

const MAIN_MENU_NAME := "MainMenu"
const MAIN_MENU_PATH := "res://Scenes/Menus/MainMenu.tscn"
const FADE_DURATION := 0.2

@onready var panel: Control = $Panel
@onready var hint_box: Control = $HintBox
@onready var hint_label: Label = $HintBox/HintLabel

@onready var resume_button: Button = $Panel/VBoxContainer/Resume
@onready var reset_button: Button = $Panel/VBoxContainer/Reset
@onready var quit_button: Button = $Panel/VBoxContainer/Quit

var hint_tween: Tween
var panel_tween: Tween

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
	print("ESC MENU LOADED")
	visible = true
	panel.visible = false
	panel.modulate.a = 0.0
	hint_box.modulate.a = 0.0

	buttons = [resume_button, reset_button, quit_button]

	for i in range(buttons.size()):
		var button := buttons[i]

		if button == null:
			push_error("A button path is wrong in esc_menu.gd")
			continue

		button.focus_mode = Control.FOCUS_NONE
		button.mouse_entered.connect(_on_button_mouse_entered.bind(i))

		original_normal_styles[button] = button.get_theme_stylebox("normal")
		hover_styles[button] = button.get_theme_stylebox("hover")
		pressed_styles[button] = button.get_theme_stylebox("pressed")

	_set_current_button(0)

	if _is_main_menu():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_update_hint(true)
	GameManager.set_menu_open(false)

	print("Controllers connected: ", Input.get_connected_joypads())


func _process(_delta: float) -> void:
	if _is_main_menu():
		_force_hide_menu()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return

	_update_hint()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if _is_main_menu():
			close_menu()
			get_viewport().set_input_as_handled()
			return

		if panel.visible:
			close_menu()
		else:
			open_menu()

		get_viewport().set_input_as_handled()
		return

	if not panel.visible:
		return

	if event is InputEventMouseMotion:
		if using_keyboard:
			_use_mouse_input()
		return

	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_W or event.keycode == KEY_UP:
			_use_keyboard_input()
			_move_selection(-1)
			get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_S or event.keycode == KEY_DOWN:
			_use_keyboard_input()
			_move_selection(1)
			get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_use_keyboard_input()
			_press_current_button()
			get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_I:
			print("DEBUG: DPAD UP")
			_use_keyboard_input()
			_move_selection(-1)
			get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_K:
			print("DEBUG: DPAD DOWN")
			_use_keyboard_input()
			_move_selection(1)
			get_viewport().set_input_as_handled()
			return

		if event.keycode == KEY_J:
			print("DEBUG: A BUTTON / CONFIRM")
			_use_keyboard_input()
			_press_current_button()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventJoypadButton and event.pressed:
		_use_keyboard_input()

		print("Controller button: ", event.button_index)

		if event.button_index == JOY_BUTTON_DPAD_UP:
			_move_selection(-1)
			get_viewport().set_input_as_handled()
			return

		if event.button_index == JOY_BUTTON_DPAD_DOWN:
			_move_selection(1)
			get_viewport().set_input_as_handled()
			return

		if event.button_index == 0:
			_press_current_button()
			get_viewport().set_input_as_handled()
			return

	if event is InputEventJoypadMotion and event.axis == JOY_AXIS_LEFT_Y:
		_use_keyboard_input()

		print("Stick Y: ", event.axis_value)

		if stick_ready:
			if event.axis_value > stick_deadzone:
				stick_ready = false
				_move_selection(1)
				get_viewport().set_input_as_handled()
				return
			elif event.axis_value < -stick_deadzone:
				stick_ready = false
				_move_selection(-1)
				get_viewport().set_input_as_handled()
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
	_refresh_button_styles()


func open_menu() -> void:
	if _is_main_menu():
		close_menu()
		return

	if panel_tween:
		panel_tween.kill()

	panel.visible = true
	panel_tween = create_tween()
	panel_tween.tween_property(panel, "modulate:a", 1.0, FADE_DURATION)

	GameManager.set_menu_open(true)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	using_keyboard = false
	_set_current_button(current_index)


func close_menu() -> void:
	if panel_tween:
		panel_tween.kill()

	panel_tween = create_tween()
	panel_tween.tween_property(panel, "modulate:a", 0.0, FADE_DURATION)
	panel_tween.finished.connect(func():
		panel.visible = false
	)

	GameManager.set_menu_open(false)

	if _is_main_menu():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	using_keyboard = false


func _is_main_menu() -> bool:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return false
	return current_scene.name == MAIN_MENU_NAME


func _update_hint(force := false) -> void:
	var should_show := not _is_main_menu() and not panel.visible

	if force:
		hint_box.visible = should_show
		hint_box.modulate.a = 1.0 if should_show else 0.0
		return

	if hint_tween:
		hint_tween.kill()

	if should_show:
		hint_box.visible = true
		hint_tween = create_tween()
		hint_tween.tween_property(hint_box, "modulate:a", 1.0, FADE_DURATION)
	else:
		hint_tween = create_tween()
		hint_tween.tween_property(hint_box, "modulate:a", 0.0, FADE_DURATION)
		hint_tween.finished.connect(func():
			hint_box.visible = false
		)


func _move_selection(direction: int) -> void:
	if is_pressing:
		return

	var new_index := current_index + direction

	if new_index < 0:
		new_index = buttons.size() - 1
	elif new_index >= buttons.size():
		new_index = 0

	_set_current_button(new_index)


func _set_current_button(index: int) -> void:
	current_index = index
	_refresh_button_styles()


func _refresh_button_styles() -> void:
	for i in range(buttons.size()):
		var button := buttons[i]
		if button == null:
			continue

		if i == current_index and using_keyboard:
			_apply_selected_style(button)
		else:
			_apply_normal_style(button)


func _apply_normal_style(button: Button) -> void:
	if original_normal_styles.has(button) and original_normal_styles[button] != null:
		button.add_theme_stylebox_override("normal", original_normal_styles[button])
	button.scale = Vector2(1.0, 1.0)


func _apply_selected_style(button: Button) -> void:
	if hover_styles.has(button) and hover_styles[button] != null:
		button.add_theme_stylebox_override("normal", hover_styles[button])
	button.scale = Vector2(1.03, 1.03)


func _apply_pressed_style(button: Button) -> void:
	if pressed_styles.has(button) and pressed_styles[button] != null:
		button.add_theme_stylebox_override("normal", pressed_styles[button])
	button.scale = Vector2(0.97, 0.97)


func _press_current_button() -> void:
	if is_pressing:
		return

	is_pressing = true
	var button := buttons[current_index]

	_apply_pressed_style(button)

	await get_tree().create_timer(0.08).timeout

	is_pressing = false
	_refresh_button_styles()

	match current_index:
		0:
			_on_resume_pressed()
		1:
			_on_reset_pressed()
		2:
			_on_quit_pressed()


func _on_button_mouse_entered(index: int) -> void:
	if is_pressing:
		return

	_use_mouse_input()
	current_index = index
	_refresh_button_styles()


func _on_resume_pressed() -> void:
	close_menu()


func _on_reset_pressed() -> void:
	close_menu()
	GameManager.reset_player_to_spawn()


func _on_quit_pressed() -> void:
	GameManager.set_menu_open(false)
	using_keyboard = false

	if panel_tween:
		panel_tween.kill()

	panel.visible = false
	panel.modulate.a = 0.0
	hint_box.visible = false
	hint_box.modulate.a = 0.0

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("QUIT PRESSED")
	print("Changing to: ", MAIN_MENU_PATH)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _force_hide_menu() -> void:
	if panel_tween:
		panel_tween.kill()

	panel.visible = false
	panel.modulate.a = 0.0
	hint_box.visible = false
	hint_box.modulate.a = 0.0
	using_keyboard = false
	GameManager.set_menu_open(false)
