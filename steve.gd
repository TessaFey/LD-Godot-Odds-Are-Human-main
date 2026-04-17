extends CharacterBody3D

@export var speed: float = 15.0
@export var jump_velocity: float = 7.5

@export var rise_gravity_mult: float = 0.7
@export var fall_gravity_mult: float = 4.0
@export var gravity_lerp_speed: float = 6.0
@export var short_hop_cut: float = 0.5
@export var enable_short_hop: bool = true

@export var mouse_sensitivity: float = 0.12
@export var stick_sensitivity: float = 180.0
@export var stick_deadzone: float = 0.15
var camera_pitch: float = 0.0
@export var max_look_angle: float = 80.0

# Third-person camera settings
@export var camera_distance: float = 5.0
@export var camera_height: float = 1.5

@onready var anim: AnimationPlayer = $Rig_Medium/AnimationPlayer
@onready var visual: Node3D = $Rig_Medium
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity") * 1.2
var gravity_mult: float = 1.0
var _current_anim: StringName = &""

var jump_count: int = 0
const MAX_JUMPS := 2
@export var double_jump_multiplier: float = 0.85

@export var air_dash_speed: float = 22.0
@export var air_dash_time: float = 0.2
var air_dash_timer: float = 0.0
var air_dash_direction: Vector3 = Vector3.ZERO
var has_air_dashed: bool = false

const MODEL_FACING_OFFSET := 0.0
const TURN_SPEED := 10.0

var camera_yaw: float = 0.0


func _ready():
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	spring_arm.spring_length = camera_distance
	spring_arm.position.y = camera_height
	spring_arm.set_as_top_level(true)

	if anim == null:
		push_error("AnimationPlayer not found at $Rig_Medium/AnimationPlayer")


func _unhandled_input(event):
	# Block player/gameplay input while ESC menu is open
	if GameManager.menu_open:
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_yaw -= event.relative.x * mouse_sensitivity
		camera_pitch -= event.relative.y * mouse_sensitivity
		camera_pitch = clamp(camera_pitch, -max_look_angle, max_look_angle)

	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _play_anim(name: StringName) -> void:
	if anim == null or not anim.has_animation(name):
		return
	if _current_anim == name:
		return
	_current_anim = name
	anim.play(name)


func _physics_process(delta):
	# Keep world running, but lock the player while menu is open
	if GameManager.menu_open:
		velocity.x = 0.0
		velocity.z = 0.0
		air_dash_timer = 0.0
		move_and_slide()

		if not is_on_floor():
			_play_anim(&"Player/Jump_Full_Long")
		else:
			_play_anim(&"Player/T-Pose")
		return

	# ---------------- CAMERA ORBIT (spring arm) ----------------
	var look_x := Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	if abs(look_x) > stick_deadzone:
		camera_yaw -= look_x * stick_sensitivity * delta

	var look_y := Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	if abs(look_y) > stick_deadzone:
		camera_pitch -= look_y * stick_sensitivity * delta
		camera_pitch = clamp(camera_pitch, -max_look_angle, max_look_angle)

	spring_arm.global_position = global_position + Vector3(0, camera_height, 0)
	spring_arm.rotation_degrees.x = camera_pitch
	spring_arm.rotation_degrees.y = camera_yaw

	# ---------------- MOVEMENT INPUT ----------------
	var input_dir: Vector2 = Input.get_vector("left", "right", "forward", "back")

	var yaw_rad := deg_to_rad(camera_yaw)
	var forward := Vector3(-sin(yaw_rad), 0, -cos(yaw_rad)).normalized()
	var right := Vector3(cos(yaw_rad), 0, -sin(yaw_rad)).normalized()

	var direction: Vector3 = (forward * -input_dir.y) + (right * input_dir.x)
	if direction.length() > 0.0:
		direction = direction.normalized()

	# ---------------- AIR DASH ----------------
	if Input.is_action_just_pressed("Dash") and not is_on_floor() and not has_air_dashed:
		has_air_dashed = true
		air_dash_timer = air_dash_time
		air_dash_direction = direction if direction.length() > 0.0 else (-global_transform.basis.z * Vector3(1, 0, 1)).normalized()
		velocity.y = 0.0

	# ---------------- AIR DASH ACTIVE ----------------
	if air_dash_timer > 0.0:
		air_dash_timer -= delta
		velocity.x = air_dash_direction.x * air_dash_speed
		velocity.z = air_dash_direction.z * air_dash_speed
		velocity.y = 0.0
	else:
		# ---------------- GRAVITY ----------------
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
			velocity.y = jump_velocity if jump_count == 0 else jump_velocity * double_jump_multiplier
			jump_count += 1

		if enable_short_hop and Input.is_action_just_released("jump") and velocity.y > 0:
			velocity.y *= short_hop_cut

		# ---------------- MOVEMENT ----------------
		if direction.length() > 0.0:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
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
