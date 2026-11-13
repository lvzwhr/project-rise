class_name CameraRig
extends Node3D

var player: Node3D
var locked: bool = false
var lock_target: Node3D
var yaw: float = 0.0
var pitch: float = -0.32

var _arm: SpringArm3D
var _cam: Camera3D


func _ready() -> void:
	_arm = SpringArm3D.new()
	_arm.spring_length = 5.1
	_arm.margin = 0.22
	_arm.collision_mask = CombatConsts.LAYER_WORLD
	_arm.position = Vector3(0.45, 1.42, 0.0)
	add_child(_arm)
	_cam = Camera3D.new()
	_cam.fov = 55.0
	_cam.near = 0.12
	_cam.far = 120.0
	_cam.current = true
	_arm.add_child(_cam)


func set_lock(on: bool, target: Node3D) -> void:
	locked = on
	lock_target = target


func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if locked:
		return
	if event is InputEventMouseMotion:
		yaw -= event.relative.x * 0.0042
		pitch = clampf(pitch - event.relative.y * 0.003, -1.05, 0.38)


func _physics_process(delta: float) -> void:
	if player == null:
		return
	global_position = player.global_position
	if not locked:
		_stick_look(delta)
	if locked and is_instance_valid(lock_target):
		var to := lock_target.global_position - player.global_position
		to.y = 0.0
		if to.length_squared() > 0.0001:
			var desired := atan2(to.x, to.z)
			yaw = lerp_angle(yaw, desired, clampf(10.0 * delta, 0.0, 1.0))
		pitch = lerp(pitch, -0.22, clampf(6.0 * delta, 0.0, 1.0))
		_try_riposte_pushin(delta)
	rotation.y = yaw
	_arm.rotation.x = pitch


func _stick_look(delta: float) -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var id := Input.get_connected_joypads()[0]
	var rs := Vector2(Input.get_joy_axis(id, JOY_AXIS_RIGHT_X), Input.get_joy_axis(id, JOY_AXIS_RIGHT_Y))
	if rs.length() < 0.18:
		return
	yaw -= rs.x * 2.4 * delta
	pitch = clampf(pitch - rs.y * 1.7 * delta, -1.05, 0.38)


func _try_riposte_pushin(delta: float) -> void:
	if player is PlayerKnight and (player as PlayerKnight).state_name == "Riposte":
		_arm.spring_length = lerpf(_arm.spring_length, 3.6, clampf(8.0 * delta, 0.0, 1.0))
	else:
		_arm.spring_length = lerpf(_arm.spring_length, 5.1, clampf(6.0 * delta, 0.0, 1.0))
