class_name PlayerKnight
extends CombatActor

enum State {
	Idle, Walk, Run, Light1, Light2, Light3, Heavy, ChargedHeavy,
	Jump, JumpAttack, RunningAttack, DodgeRoll, Guard, GuardHit,
	GuardBreak, Exhaust, Hitstun, Riposte, Death
}

var state: State = State.Idle
var stamina: float = CombatConsts.PLAYER_STAMINA
var regen_delay: int = 0
var lock_on: bool = false
var lock_target: CombatActor = null
var frames_since_roll_end: int = 999
var last_hitstun_class: AttackData.HitstunClass = AttackData.HitstunClass.LIGHT

var _buf_action: StringName = &""
var _buf_frames: int = 0
var _run_frames: int = 0
var _forward_hold: int = 0
var _stumble: int = 0
var _guard_lowering: int = 0
var _guard_to_roll: int = 0
var _guard_active: bool = false
var _charge_frames: int = 0
var _charging: bool = false
var _ground_rec: int = 0
var _hitstun_left: int = 0
var _getup_at: int = -1
var _knock: Vector3 = Vector3.ZERO
var _roll_dir: Vector3 = Vector3.ZERO
var _camera: Node3D
var _heavy_held: bool = false
var _want_light: bool = false
var _want_heavy: bool = false
var _want_roll: bool = false
var _want_jump: bool = false
var _want_lock: bool = false
var _guard_held: bool = false
var _run_held: bool = false
var _stick: Vector2 = Vector2.ZERO
var _move_dir: Vector3 = Vector3.ZERO
var _enemy: CombatActor


func _ready() -> void:
	team = Team.PLAYER
	actor_id = "player"
	max_hp = CombatConsts.PLAYER_HP
	hp = max_hp
	stamina = CombatConsts.PLAYER_STAMINA
	super._ready()
	build_rig(0.28, 1.78, CombatConsts.COLOR_PLAYER, CombatConsts.COLOR_PLAYER_SWORD, Color("#8AA0B4"), 0.85, "res://assets/characters/player_knight_visual.tscn")
	add_to_group("player")
	_enter(State.Idle)


func bind_world(camera: Node3D, enemy: CombatActor) -> void:
	_camera = camera
	_enemy = enemy


func _physics_process(delta: float) -> void:
	_read_input()
	_store_buffer()
	if _want_lock:
		_toggle_lock()
	_update_lock()
	if frames_since_roll_end < 10000:
		frames_since_roll_end += 1
	_tick_stamina(delta)
	_fsm(delta)
	if hitbox_on:
		try_hits()
	apply_gravity(delta)
	move_and_slide()
	_tick_buffer_end()
	post_visual(delta)
	_debug_keys()


func _read_input() -> void:
	_want_light = Input.is_action_just_pressed("light")
	_want_heavy = Input.is_action_just_pressed("heavy")
	_heavy_held = Input.is_action_pressed("heavy")
	_want_jump = Input.is_action_just_pressed("jump")
	_want_lock = Input.is_action_just_pressed("lock_on")
	_want_roll = Input.is_action_just_pressed("roll")
	_guard_held = Input.is_action_pressed("guard")
	var b_held := false
	if Input.get_connected_joypads().size() > 0:
		b_held = Input.is_joy_button_pressed(Input.get_connected_joypads()[0], JOY_BUTTON_B)
	var shift := Input.is_physical_key_pressed(KEY_SHIFT)
	_run_held = shift or (b_held and not _want_roll)
	_stick = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_move_dir = _basis_move(_stick)


func _basis_move(stick: Vector2) -> Vector3:
	if stick.length() < 0.01:
		return Vector3.ZERO
	var forward := Vector3(0, 0, 1)
	var right := Vector3(1, 0, 0)
	if lock_on and is_instance_valid(lock_target):
		forward = lock_target.global_position - global_position
		forward.y = 0.0
		if forward.length_squared() < 0.0001:
			forward = get_forward()
		else:
			forward = forward.normalized()
		right = Vector3.UP.cross(forward).normalized()
	elif _camera:
		forward = -_camera.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() < 0.0001:
			forward = get_forward()
		else:
			forward = forward.normalized()
		right = Vector3.UP.cross(forward).normalized()
	var dir := forward * -stick.y + right * stick.x
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return Vector3.ZERO
	return dir.normalized() * minf(stick.length(), 1.0)


func _store_buffer() -> void:
	if _want_light:
		_set_buf(&"Light")
	elif _want_heavy:
		_set_buf(&"Heavy")
	elif _want_roll:
		_set_buf(&"Roll")
	elif _want_jump:
		_set_buf(&"Jump")
	elif Input.is_action_just_pressed("guard"):
		_set_buf(&"Guard")


func _set_buf(a: StringName) -> void:
	_buf_action = a
	_buf_frames = CombatConsts.BUFFER_MEMORY_FRAMES


func _tick_buffer_end() -> void:
	if _buf_frames > 0:
		_buf_frames -= 1
		if _buf_frames <= 0:
			_buf_action = &""


func _toggle_lock() -> void:
	if lock_on:
		lock_on = false
		lock_target = null
		if _camera and _camera.has_method("set_lock"):
			_camera.set_lock(false, null)
		return
	_try_acquire()


func _try_acquire() -> void:
	if _enemy == null or _enemy.hp <= 0:
		return
	if planar_distance_to(_enemy) <= CombatConsts.LOCK_ACQUIRE:
		lock_on = true
		lock_target = _enemy
		if _camera and _camera.has_method("set_lock"):
			_camera.set_lock(true, _enemy)


func _update_lock() -> void:
	if not lock_on:
		return
	if lock_target == null or not is_instance_valid(lock_target) or lock_target.hp <= 0:
		lock_on = false
		lock_target = null
	elif planar_distance_to(lock_target) > CombatConsts.LOCK_DROP:
		lock_on = false
		lock_target = null
	if _camera and _camera.has_method("set_lock"):
		_camera.set_lock(lock_on, lock_target)


func lock_distance() -> float:
	if lock_on and lock_target:
		return planar_distance_to(lock_target)
	return -1.0


func _tick_stamina(delta: float) -> void:
	if state == State.Run and _run_frames > CombatConsts.SPRINT_FREE_FRAMES and _stumble == 0:
		stamina = maxf(0.0, stamina - CombatConsts.SPRINT_DRAIN_PER_SEC * delta)
		regen_delay = CombatConsts.STAMINA_REGEN_DELAY_FRAMES
		if stamina <= 0.0:
			stamina = 0.0
			_stumble = CombatConsts.SPRINT_STUMBLE_FRAMES
			_enter(State.Walk)
			return
	if regen_delay > 0:
		regen_delay -= 1
		return
	if _can_regen():
		stamina = minf(CombatConsts.PLAYER_STAMINA, stamina + CombatConsts.STAMINA_REGEN_PER_SEC * delta)


func _can_regen() -> bool:
	match state:
		State.Idle, State.Walk, State.Guard:
			return _stumble <= 0
		_:
			return false


func _pay(cost: int) -> bool:
	if cost <= 0:
		return true
	if stamina <= 0.0:
		return false
	stamina = maxf(0.0, stamina - float(cost))
	regen_delay = CombatConsts.STAMINA_REGEN_DELAY_FRAMES
	return true


func _would_exhaust(cost: int) -> bool:
	return cost > 0 and stamina <= 0.0


func _fsm(delta: float) -> void:
	if _stumble > 0 and state != State.Walk:
		pass
	match state:
		State.Idle:
			_st_idle(delta)
		State.Walk:
			_st_walk(delta)
		State.Run:
			_st_run(delta)
		State.Light1, State.Light2, State.Light3, State.Heavy, State.RunningAttack, State.Riposte:
			_st_attack(delta)
		State.ChargedHeavy:
			_st_charged(delta)
		State.Jump:
			_st_jump(delta)
		State.JumpAttack:
			_st_jump_attack(delta)
		State.DodgeRoll:
			_st_roll(delta)
		State.Guard:
			_st_guard(delta)
		State.GuardHit:
			_st_guard_hit(delta)
		State.GuardBreak:
			_st_lockout(delta, CombatConsts.GUARD_BREAK_FRAMES, true)
		State.Exhaust:
			_st_exhaust(delta)
		State.Hitstun:
			_st_hitstun(delta)
		State.Death:
			_st_death(delta)


func _st_idle(delta: float) -> void:
	state_name = "Idle"
	phase = "—"
	local_frame += 1
	stop_horizontal()
	if _stumble > 0:
		_stumble -= 1
		return
	if _stick.length() >= CombatConsts.STICK_WALK:
		_enter(State.Walk)
		return
	if _try_run_start():
		return
	_try_locomotion_actions()


func _st_walk(delta: float) -> void:
	state_name = "Walk"
	phase = "—"
	local_frame += 1
	if _stumble > 0:
		_stumble -= 1
		apply_horizontal(_move_dir, 1.1)
		play_pose(&"RunStumble")
		return
	if _stick.length() < CombatConsts.STICK_WALK:
		_enter(State.Idle)
		return
	if _try_run_start():
		return
	var spd := CombatConsts.WALK_SPEED * minf(_stick.length(), 1.0)
	apply_horizontal(_move_dir, spd)
	_face_move(delta, 420.0)
	_try_locomotion_actions()


func _st_run(delta: float) -> void:
	state_name = "Run"
	phase = "—"
	local_frame += 1
	_run_frames += 1
	if not _run_held and _stick.length() < CombatConsts.STICK_RUN:
		_enter(State.Walk if _stick.length() >= CombatConsts.STICK_WALK else State.Idle)
		return
	if _guard_held:
		_enter(State.Guard)
		return
	if _want_roll or _buf_action == &"Roll":
		if _start_roll():
			return
	if _want_jump:
		if _start_jump():
			return
	if (_want_light or _want_heavy) and _run_frames >= 8:
		if _would_exhaust(18):
			_enter(State.Exhaust)
			return
		if _pay(18):
			_enter(State.RunningAttack)
			return
	apply_horizontal(_move_dir if _move_dir.length() > 0.1 else get_forward(), CombatConsts.RUN_SPEED)
	_face_move(delta, 480.0)


func _try_run_start() -> bool:
	var forward_amt := 0.0
	if _move_dir.length() > 0.01:
		forward_amt = _stick.length()
	if _run_held:
		_enter(State.Run)
		return true
	var looking_forward := _stick.y < -CombatConsts.STICK_RUN + 0.01 or (_lock_on_forward_stick() >= CombatConsts.STICK_RUN)
	if looking_forward and _stick.length() >= CombatConsts.STICK_RUN:
		_forward_hold += 1
		if _forward_hold >= CombatConsts.STICK_RUN_HOLD_FRAMES:
			_enter(State.Run)
			return true
	else:
		_forward_hold = 0
	return false


func _lock_on_forward_stick() -> float:
	if not lock_on:
		return -_stick.y
	return -_stick.y


func _face_move(delta: float, deg: float) -> void:
	if lock_on and is_instance_valid(lock_target):
		turn_towards(lock_target.global_position, deg, delta)
	elif _move_dir.length() > 0.05:
		face_dir(_move_dir)


func _try_locomotion_actions() -> void:
	if _consume_or_press():
		return
	if _guard_held:
		_enter(State.Guard)


func _buffer_open() -> bool:
	match state:
		State.Idle, State.Walk:
			return true
		_:
			return can_buffer_flag


func _consume_or_press() -> bool:
	if not _buffer_open():
		return false
	var act := _buf_action
	if act == &"":
		return false
	return _consume(act)


func _consume(act: StringName) -> bool:
	match act:
		&"Light":
			return _start_light()
		&"Heavy":
			if _try_riposte():
				return true
			_buf_action = &""
			_enter(State.ChargedHeavy)
			return true
		&"Roll":
			return _start_roll()
		&"Jump":
			return _start_jump()
		&"Guard":
			_buf_action = &""
			_enter(State.Guard)
			return true
	return false


func _try_riposte() -> bool:
	if _enemy == null:
		return false
	if _enemy.state_name != "StanceBroken":
		return false
	if planar_distance_to(_enemy) > CombatConsts.RIPOSTE_RANGE:
		return false
	_buf_action = &""
	_enter(State.Riposte)
	return true


func _start_light() -> bool:
	if _try_riposte():
		return true
	if state == State.Light3:
		return false
	var nxt := State.Light1
	var cost := 13
	if state == State.Light1 and can_buffer_flag:
		nxt = State.Light2
		cost = 13
	elif state == State.Light2 and can_buffer_flag:
		nxt = State.Light3
		cost = 16
	if _would_exhaust(cost):
		_buf_action = &""
		_enter(State.Exhaust)
		return true
	if not _pay(cost):
		return false
	_buf_action = &""
	_enter(nxt)
	return true


func _start_roll() -> bool:
	if _would_exhaust(20):
		_buf_action = &""
		_enter(State.Exhaust)
		return true
	if state == State.Guard or state == State.GuardHit:
		_buf_action = &""
		_guard_to_roll = CombatConsts.GUARD_ROLL_DROP_FRAMES
		_guard_active = false
		phase = "lower"
		return true
	if not _pay(20):
		return false
	_buf_action = &""
	_enter(State.DodgeRoll)
	return true


func _start_jump() -> bool:
	if stamina <= 0.0:
		return false
	if not _pay(CombatConsts.JUMP_STAMINA):
		return false
	_buf_action = &""
	_enter(State.Jump)
	return true


func _st_attack(delta: float) -> void:
	local_frame += 1
	tick_attack_events()
	apply_step_this_frame(current_attack)
	if lock_on and is_instance_valid(lock_target) and phase == "startup" and local_frame <= 4:
		turn_towards(lock_target.global_position, 180.0, delta)
	if state == State.Riposte and local_frame == 17:
		_riposte_connect()
	if can_buffer_flag:
		_try_recovery_cancels()
	if current_attack and local_frame >= current_attack.total:
		_enter(State.Idle)


func _try_recovery_cancels() -> void:
	if _buf_action == &"":
		return
	if state == State.Light3 and _buf_action == &"Light":
		return
	_consume(_buf_action)


func _st_charged(delta: float) -> void:
	if _charging:
		_charge_frames += 1
		local_frame = _charge_frames
		state_name = "ChargedHeavy"
		phase = "charge"
		if _charge_frames == 12:
			hyperarmor_on()
		var walk := _move_dir
		if walk.length() < 0.05 and lock_on and lock_target:
			walk = Vector3.ZERO
		apply_horizontal(walk, CombatConsts.CHARGE_WALK)
		if lock_on and lock_target:
			turn_towards(lock_target.global_position, CombatConsts.CHARGE_TURN_DEG, delta)
		if (not _heavy_held and _charge_frames >= 1) or _charge_frames >= CombatConsts.CHARGE_MAX:
			if _charge_frames < CombatConsts.CHARGE_MIN and _charge_frames < CombatConsts.CHARGE_MAX:
				if _would_exhaust(24):
					_enter(State.Exhaust)
					return
				if _pay(24):
					hyperarmor = false
					_enter(State.Heavy)
				return
			if _would_exhaust(36):
				_enter(State.Exhaust)
				return
			if _pay(36):
				_charging = false
				begin_attack(MoveDB.get_move(&"ChargedHeavy"))
				_face_on_attack()
				play_pose(&"ChargedHeavy_Release")
			return
		return
	local_frame += 1
	tick_attack_events()
	apply_step_this_frame(current_attack)
	if can_buffer_flag:
		_try_recovery_cancels()
	if current_attack and local_frame >= current_attack.total:
		_enter(State.Idle)


func _st_jump(delta: float) -> void:
	state_name = "Jump"
	local_frame += 1
	phase = "rise" if local_frame <= CombatConsts.JUMP_RISE_FRAMES else "fall"
	iframe = false
	var air_end := CombatConsts.JUMP_RISE_FRAMES + CombatConsts.JUMP_FALL_FRAMES
	if local_frame >= CombatConsts.JUMP_ATTACK_WINDOW_START and local_frame <= air_end - 2:
		if _want_light or _want_heavy or _buf_action == &"Light" or _buf_action == &"Heavy":
			if _would_exhaust(14):
				_enter(State.Exhaust)
				return
			if _pay(14):
				_buf_action = &""
				_enter(State.JumpAttack)
				return
	if _move_dir.length() > 0.1:
		apply_horizontal(_move_dir, CombatConsts.WALK_SPEED * 0.7)
		if not lock_on:
			face_dir(_move_dir)
	else:
		velocity.x *= 0.92
		velocity.z *= 0.92
	if is_on_floor() and local_frame > CombatConsts.JUMP_RISE_FRAMES:
		phase = "land"
		stop_horizontal()
		if local_frame >= air_end + CombatConsts.JUMP_LAND_FRAMES:
			_enter(State.Idle)


func _st_jump_attack(delta: float) -> void:
	state_name = "JumpAttack"
	local_frame += 1
	tick_attack_events()
	if local_frame <= current_attack.startup + current_attack.active:
		apply_horizontal(get_forward(), current_attack.step_distance / ((current_attack.startup + current_attack.active) / 60.0))
	if is_on_floor() and local_frame >= current_attack.hit_off:
		_ground_rec += 1
		phase = "recovery"
		stop_horizontal()
		if _ground_rec == 17:
			can_buffer()
		if _ground_rec > 24:
			can_buffer_flag = false
		if can_buffer_flag:
			_try_recovery_cancels()
		if _ground_rec >= current_attack.recovery:
			_enter(State.Idle)
	elif is_on_floor() and local_frame < current_attack.hit_off:
		stop_horizontal()


func _st_roll(delta: float) -> void:
	state_name = "DodgeRoll"
	local_frame += 1
	tick_attack_events()
	var spd := CombatConsts.ROLL_DISTANCE / (float(CombatConsts.ROLL_FRAMES) / 60.0)
	apply_horizontal(_roll_dir, spd)
	if local_frame <= 3:
		phase = "startup"
	elif iframe:
		phase = "iframe"
	else:
		phase = "recovery"
	if can_buffer_flag:
		_try_recovery_cancels()
	if local_frame >= CombatConsts.ROLL_FRAMES:
		frames_since_roll_end = 0
		_enter(State.Idle)


func _st_guard(delta: float) -> void:
	state_name = "Guard"
	local_frame += 1
	stop_horizontal()
	if lock_on and lock_target:
		turn_towards(lock_target.global_position, 360.0, delta)
	if _guard_to_roll > 0:
		_guard_to_roll -= 1
		_guard_active = false
		phase = "lower"
		if _guard_to_roll <= 0:
			if _would_exhaust(20):
				_enter(State.Exhaust)
			elif _pay(20):
				_enter(State.DodgeRoll)
		return
	if local_frame <= CombatConsts.GUARD_RAISE_FRAMES:
		phase = "raise"
		_guard_active = false
	else:
		if _guard_lowering > 0:
			phase = "lower"
			_guard_active = false
			play_pose(&"Guard_Lower")
			_guard_lowering -= 1
			if _guard_lowering <= 4:
				can_buffer_flag = true
				if _buf_action == &"Roll" or _buf_action == &"Light" or _buf_action == &"Heavy" or _buf_action == &"Jump":
					_consume(_buf_action)
					return
			if _guard_lowering <= 0:
				_enter(State.Idle)
			return
		phase = "hold"
		_guard_active = true
		can_buffer_flag = false
		play_pose(&"Guard_Hold")
		if not _guard_held:
			_guard_lowering = CombatConsts.GUARD_LOWER_FRAMES
			_guard_active = false
			phase = "lower"
		elif _want_roll or _buf_action == &"Roll":
			_start_roll()


func _st_guard_hit(_delta: float) -> void:
	state_name = "GuardHit"
	phase = "hit"
	local_frame += 1
	_guard_active = true
	stop_horizontal()
	if local_frame >= CombatConsts.GUARD_HIT_FRAMES:
		if _guard_held:
			state = State.Guard
			state_name = "Guard"
			phase = "hold"
			local_frame = CombatConsts.GUARD_RAISE_FRAMES
			_guard_active = true
		else:
			_enter(State.Guard)
			_guard_lowering = CombatConsts.GUARD_LOWER_FRAMES
			_guard_active = false
			local_frame = CombatConsts.GUARD_RAISE_FRAMES


func _st_lockout(_delta: float, length: int, show_buffer: bool) -> void:
	local_frame += 1
	stop_horizontal()
	phase = "lock"
	if show_buffer and local_frame >= length - 8:
		can_buffer_flag = true
	if local_frame >= length:
		_enter(State.Idle)


func _st_exhaust(_delta: float) -> void:
	state_name = "Exhaust"
	local_frame += 1
	stop_horizontal()
	phase = "punish"
	if local_frame >= CombatConsts.EXHAUST_FRAMES - 8:
		can_buffer_flag = true
		if _buf_action == &"Guard":
			_buf_action = &""
			_enter(State.Guard)
			return
		if _stick.length() >= CombatConsts.STICK_WALK:
			_enter(State.Walk)
			return
	if local_frame >= CombatConsts.EXHAUST_FRAMES:
		_enter(State.Idle)


func _st_hitstun(_delta: float) -> void:
	state_name = "Hitstun"
	local_frame += 1
	_hitstun_left -= 1
	velocity.x = _knock.x
	velocity.z = _knock.z
	_knock *= 0.82
	if _getup_at >= 0 and local_frame > _getup_at:
		if phase != "getup":
			play_pose(&"Hitstun_SlamGetup")
		phase = "getup"
	else:
		phase = "hitstun"
	if _hitstun_left <= 0:
		_enter(State.Idle)


func _st_death(_delta: float) -> void:
	state_name = "Death"
	phase = "death"
	local_frame += 1
	stop_horizontal()
	iframe = true


func _riposte_connect() -> void:
	if _enemy == null or _enemy.state_name != "StanceBroken":
		hit_off()
		return
	if planar_distance_to(_enemy) > CombatConsts.RIPOSTE_RANGE:
		hit_off()
		return
	if _enemy in _already_hit:
		return
	_already_hit.append(_enemy)
	_enemy.receive_hit(self, current_attack)


func _enter(s: State) -> void:
	clear_combat_flags()
	hyperarmor = false
	_guard_active = false
	_charging = false
	_ground_rec = 0
	current_attack = null
	state = s
	local_frame = 0
	can_buffer_flag = false
	state_name = State.keys()[s]
	match s:
		State.Idle:
			phase = "—"
			_run_frames = 0
			_forward_hold = 0
			play_pose(&"Idle")
			_consume_or_press()
		State.Walk:
			phase = "—"
			play_pose(&"Walk")
			_consume_or_press()
		State.Run:
			phase = "—"
			_run_frames = 0
			play_pose(&"Run")
		State.Light1:
			begin_attack(MoveDB.get_move(&"Light1"))
			_face_on_attack()
			play_pose(&"Light1")
		State.Light2:
			begin_attack(MoveDB.get_move(&"Light2"))
			_face_on_attack()
			play_pose(&"Light2")
		State.Light3:
			begin_attack(MoveDB.get_move(&"Light3"))
			_face_on_attack()
			play_pose(&"Light3")
		State.Heavy:
			begin_attack(MoveDB.get_move(&"Heavy"))
			_face_on_attack()
			play_pose(&"Heavy")
		State.ChargedHeavy:
			_charging = true
			_charge_frames = 0
			phase = "charge"
			current_attack = null
			play_pose(&"ChargedHeavy_Charge")
		State.Jump:
			phase = "rise"
			jump_launch()
			iframe = false
			play_pose(&"Jump")
		State.JumpAttack:
			begin_attack(MoveDB.get_move(&"JumpAttack"))
			_ground_rec = 0
			_face_on_attack()
			play_pose(&"JumpAttack")
		State.RunningAttack:
			begin_attack(MoveDB.get_move(&"RunningAttack"))
			_face_on_attack()
			play_pose(&"RunningAttack")
		State.DodgeRoll:
			begin_attack(MoveDB.get_move(&"DodgeRoll"))
			_roll_dir = _pick_roll_dir()
			if _roll_dir.length() > 0.01:
				face_dir(_roll_dir)
			play_pose(&"DodgeRoll")
		State.Guard:
			phase = "raise"
			_guard_lowering = 0
			_guard_to_roll = 0
			_run_frames = 0
			play_pose(&"Guard_Raise")
		State.GuardHit:
			phase = "hit"
			_guard_active = true
			play_pose(&"GuardHit")
		State.GuardBreak:
			phase = "lock"
			_guard_active = false
			play_pose(&"GuardBreak")
		State.Exhaust:
			phase = "punish"
			play_pose(&"Exhaust")
		State.Hitstun:
			phase = "hitstun"
			_play_hitstun_pose()
		State.Riposte:
			begin_attack(MoveDB.get_move(&"Riposte"))
			hyperarmor_on()
			_face_on_attack()
			play_pose(&"Riposte")
		State.Death:
			phase = "death"
			hp = 0
			iframe = true
			play_pose(&"Death")
			CombatBus.actor_died.emit(self)


func _play_hitstun_pose() -> void:
	match last_hitstun_class:
		AttackData.HitstunClass.HEAVY:
			play_pose(&"Hitstun_Heavy")
		AttackData.HitstunClass.SLAM:
			play_pose(&"Hitstun_Slam")
		_:
			play_pose(&"Hitstun_Light")


func _face_on_attack() -> void:
	if lock_on and is_instance_valid(lock_target):
		turn_towards(lock_target.global_position, 10000.0, 1.0)
	elif _move_dir.length() > 0.1:
		face_dir(_move_dir)


func _pick_roll_dir() -> Vector3:
	if _move_dir.length() > 0.15:
		return _move_dir.normalized()
	if lock_on and is_instance_valid(lock_target):
		var away := global_position - lock_target.global_position
		away.y = 0.0
		if away.length_squared() > 0.0001:
			return away.normalized()
	if _camera:
		var f := -_camera.global_transform.basis.z
		f.y = 0.0
		if f.length_squared() > 0.0001:
			return f.normalized()
	return get_forward()


func handle_block(attacker: CombatActor, atk: AttackData) -> bool:
	if not _guard_active:
		return false
	if not is_in_front_of_me(attacker):
		return false
	var cost := atk.block_stamina
	if stamina - float(cost) < 0.0:
		stamina = 0.0
		regen_delay = CombatConsts.STAMINA_REGEN_DELAY_FRAMES
		CombatBus.report_hit({
			"damage": atk.damage,
			"stance": 0,
			"blocked": false,
			"move": atk.move_id,
			"victim": actor_id,
		})
		hp = maxi(0, hp - atk.damage)
		_hurt_flash()
		if hp <= 0:
			_enter(State.Death)
			return true
		_enter(State.GuardBreak)
		return true
	stamina = maxf(0.0, stamina - float(cost))
	regen_delay = CombatConsts.STAMINA_REGEN_DELAY_FRAMES
	CombatBus.report_hit({
		"damage": 0,
		"stance": 0,
		"blocked": true,
		"move": atk.move_id,
		"victim": actor_id,
	})
	_enter(State.GuardHit)
	return true


func on_stagger(atk: AttackData, attacker: CombatActor) -> void:
	last_hitstun_class = atk.hitstun_class
	_hitstun_left = atk.hitstun_frames()
	_getup_at = atk.slam_getup_starts_at()
	var k := 4.0
	match atk.hitstun_class:
		AttackData.HitstunClass.HEAVY:
			k = 6.0
		AttackData.HitstunClass.SLAM:
			k = 8.0
		_:
			k = 3.5
	_knock = attacker.get_forward() * k
	_enter(State.Hitstun)


func on_killed(_attacker: CombatActor, _atk: AttackData) -> void:
	_enter(State.Death)


func is_in_attack_recovery() -> bool:
	if current_attack == null:
		return false
	return phase == "recovery"


func reset_to_spawn(pos: Vector3, look: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	restore_hp()
	stamina = CombatConsts.PLAYER_STAMINA
	regen_delay = 0
	_stumble = 0
	_buf_action = &""
	_buf_frames = 0
	_knock = Vector3.ZERO
	face_dir(look - pos)
	_enter(State.Idle)
	if planar_distance_to(_enemy) <= CombatConsts.LOCK_ACQUIRE:
		pass


func _debug_keys() -> void:
	if Input.is_action_just_pressed("debug_hud"):
		CombatBus.debug_hud_on = not CombatBus.debug_hud_on
	if Input.is_action_just_pressed("debug_wires"):
		CombatBus.debug_wires_on = not CombatBus.debug_wires_on
		get_tree().debug_collisions_hint = CombatBus.debug_wires_on
	if Input.is_action_just_pressed("debug_reset"):
		CombatBus.request_reset()
	if Input.is_action_just_pressed("toggle_mouse"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
