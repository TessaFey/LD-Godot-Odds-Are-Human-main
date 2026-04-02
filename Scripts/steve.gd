extends CharacterBody3D

@export var speed: float = 15.0
@export var jump_velocity: float = 7.5

# Better jump tuning
@export var rise_gravity_mult: float = 0.7
@export var fall_gravity_mult: float = 4.0
@export var gravity_lerp_speed: float = 6.0
@export var short_hop_cut: float = 0.5
@export var enable_short_hop: bool = true

# Look settings (horizontal only)
@export var mouse_sensitivity: float = 0.12
@export var stick_sensitivity: float = 180.0
@export var stick_deadzone: float = 0.15

# Drag your level camera here
@export var camera: Camera3D

@onready var anim: AnimationPlayer = $Rig_Medium/AnimationPlayer
@onready var visual: Node3D = $Rig_Medium

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")*1.2
var gravity_mult: float = 1.0
var _current_anim: StringName = &""

# Added for double jump
var jump_count: int = 0
const MAX_JUMPS := 2
@export var double_jump_multiplier: float = 0.85

# Air dash
@export var air_dash_speed: float = 22.0
@export var air_dash_time: float = 0.2
var air_dash_timer: float = 0.0
var air_dash_direction: Vector3 = Vector3.ZERO
var has_air_dashed: bool = false

# Change this if the model faces backwards
const MODEL_FACING_OFFSET := 0.0
const TURN_SPEED := 10.0

func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if camera == null:
		push_error("Assign a Camera3D to the player in the inspector!")

	if anim == null:
		push_error("AnimationPlayer not found at $Rig_Medium/AnimationPlayer")
	else:
		print("AnimationPlayer found:", anim)
		print("Available animations:", anim.get_animation_list())


func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _play_anim(name: StringName) -> void:
	if anim == null:
		print("AnimationPlayer is null")
		return

	if not anim.has_animation(name):
		print("Missing animation:", name)
		print("Available animations:", anim.get_animation_list())
		return

	if _current_anim == name:
		return

	_current_anim = name
	anim.play(name)


func _physics_process(delta):
	# ---------------- RIGHT STICK LOOK (LEFT/RIGHT ONLY) ----------------
	var look_x := -Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(look_x) > stick_deadzone:
		rotate_y(deg_to_rad(look_x * stick_sensitivity * delta))

	# ---------------- MOVEMENT INPUT ----------------
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "back")

	var forward: Vector3
	var right: Vector3

	if camera != null:
		forward = camera.global_transform.basis.z
		right = camera.global_transform.basis.x
	else:
		forward = -global_transform.basis.z
		right = global_transform.basis.x

	forward.y = 0
	right.y = 0
	forward = forward.normalized()
	right = right.normalized()

	var direction: Vector3 = (forward * input_dir.y) + (right * input_dir.x)

	if direction.length() > 0.0:
		direction = direction.normalized()

	# ---------------- AIR DASH ----------------
	if Input.is_action_just_pressed("Dash") and not is_on_floor() and not has_air_dashed:
		has_air_dashed = true
		air_dash_timer = air_dash_time

		if direction.length() > 0.0:
			air_dash_direction = direction
		else:
			air_dash_direction = -global_transform.basis.z
			air_dash_direction.y = 0
			air_dash_direction = air_dash_direction.normalized()

		velocity.y = 0.0

	# ---------------- AIR DASH ACTIVE ----------------
	if air_dash_timer > 0.0:
		air_dash_timer -= delta
		velocity.x = air_dash_direction.x * air_dash_speed
		velocity.z = air_dash_direction.z * air_dash_speed
		velocity.y = 0.0
	else:
		# ---------------- BETTER GRAVITY ----------------
		if not is_on_floor():
			var target_mult := fall_gravity_mult if velocity.y <= 0.0 else rise_gravity_mult
			gravity_mult = lerp(gravity_mult, target_mult, gravity_lerp_speed * delta)
			velocity.y -= gravity * gravity_mult * delta
		else:
			gravity_mult = 1.0
			jump_count = 0
			has_air_dashed = false

		# ---------------- JUMP ----------------
		if Input.is_action_just_pressed("jump") and jump_count < MAX_JUMPS:
			if jump_count == 0:
				velocity.y = jump_velocity
			else:
				velocity.y = jump_velocity * double_jump_multiplier
			jump_count += 1

		if enable_short_hop and Input.is_action_just_released("jump") and velocity.y > 0:
			velocity.y *= short_hop_cut

		# ---------------- MOVEMENT ----------------
		if direction.length() > 0.0:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed

			# Rotate the visible character toward movement direction
			var local_dir := basis.inverse() * direction
			var target_angle := atan2(local_dir.x, local_dir.z) + MODEL_FACING_OFFSET
			visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, TURN_SPEED * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, speed)
			velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()

	# ---------------- ANIMATION ----------------
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()

	if not is_on_floor():
		_play_anim(&"Player/Jump_Full_Long")
	elif horizontal_speed > 0.1:
		_play_anim(&"Player/Running_B")
	else:
		_play_anim(&"Player/T-Pose")
