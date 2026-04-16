extends CanvasLayer

const MAIN_MENU_NAME := "MainMenu"
const MAIN_MENU_PATH := "res://Scenes/Menus/MainMenu.tscn"
const FADE_DURATION := 0.2

@onready var panel: Control = $Panel
@onready var hint_box: Control = $HintBox
@onready var hint_label: Label = $HintBox/HintLabel

var hint_tween: Tween
var panel_tween: Tween

func _ready():
	visible = true
	panel.visible = false
	panel.modulate.a = 0.0
	hint_box.modulate.a = 0.0

	if _is_main_menu():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	_update_hint(true)

func _process(_delta):
	_update_hint()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if _is_main_menu():
			close_menu()
			return

		if panel.visible:
			close_menu()
		else:
			open_menu()

func open_menu():
	if _is_main_menu():
		close_menu()
		return

	if panel_tween:
		panel_tween.kill()

	panel.visible = true
	panel_tween = create_tween()
	panel_tween.tween_property(panel, "modulate:a", 1.0, FADE_DURATION)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close_menu():
	if panel_tween:
		panel_tween.kill()

	panel_tween = create_tween()
	panel_tween.tween_property(panel, "modulate:a", 0.0, FADE_DURATION)
	panel_tween.finished.connect(func():
		panel.visible = false
	)

	if _is_main_menu():
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _is_main_menu() -> bool:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return false

	return current_scene.name == MAIN_MENU_NAME

func _update_hint(force := false):
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

func _on_resume_pressed():
	close_menu()

func _on_reset_pressed():
	close_menu()
	GameManager.reset_player_to_spawn()

func _on_quit_pressed():
	close_menu()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_PATH)
