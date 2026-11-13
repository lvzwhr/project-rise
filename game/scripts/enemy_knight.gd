class_name EnemyKnight
extends CombatActor

enum State {
	Idle, Walk, Sweep, Thrust, Slam, DoubleSlash1, DoubleSlash2,
	Hitstun, StanceBroken, Wakeup, Death
}

var state: State = State.Idle
var stance: int = CombatConsts.ENEMY_STANCE
var stance_broken_left: int = 0
var slam_cd: int = 0
var thrust_cd: int = 0
var ds_cd: int = 0
var last_attack: StringName = &""

var _player: CombatActor
var _breath: int = 0
var _hitstun_left: int = 0
var _getup_at: int = -1
var _knock: Vector3 = Vector3.ZERO
var _circle: Node3D
var _circle_mat: StandardMaterial3D
var _turn_lock: bool = false


func _ready() -> void:
	team = Team.ENEMY
	actor_id = "enemy"
	max_hp = CombatConsts.ENEMY_HP
	hp = max_hp
	stance = CombatConsts.ENEMY_STANCE
	super._ready()
	build_rig(0.36, 1.86, CombatConsts.COLOR_ENEMY, CombatConsts.COLOR_ENEMY_SWORD, CombatConsts.COLOR_ENEMY_ACCENT, 1.25, "res://assets/characters/enemy_knight_visual.tscn")
	add_to_group("enemy")
	_build_slam_circle()
	_enter(State.Idle)


func bind_world(player: CombatActor) -> void:
	_player = player


func _build_slam_circle() -> void:
	var parent: Node3D = self
	if artist_visual:
		var feet := artist_visual.get_node_or_null("Vfx_Feet") as Node3D
		if feet:
			parent = feet
	if ResourceLoader.exists("res://assets/vfx/slam_floor_circle.tscn"):
		var packed := load("res://assets/vfx/slam_floor_circle.tscn") as PackedScene
		if packed:
			_circle = packed.instantiate() as Node3D
	if _circle == null:
		_circle_mat = StandardMaterial3D.new()
		_circle_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_circle_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_circle_mat.albedo_color = Color(CombatConsts.COLOR_TELEGRAPH, 0.42)
		_circle_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		_circle_mat.emission_enabled = true
		_circle_mat.emission = CombatConsts.COLOR_TELEGRAPH
		_circle_mat.emission_energy_multiplier = 1.2
		var mesh_i := MeshInstance3D.new()
		var mesh := CylinderMesh.new()
		mesh.top_radius = 1.6
		mesh.bottom_radius = 1.6
		mesh.height = 0.04
		mesh.rings = 1
		mesh.radial_segments = 32
		mesh_i.mesh = mesh
		mesh_i.material_override = _circle_mat
		mesh_i.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_circle = mesh_i
	parent.add_child(_circle)
	_circle.visible = false
	_circle.position = Vector3(0.0, 0.03, 0.0)


func _physics_process(delta: float) -> void:
	if slam_cd > 0:
		slam_cd -= 1
	if thrust_cd > 0:
		thrust_cd -= 1
	if ds_cd > 0:
		ds_cd -= 1
	if _breath > 0 and not _is_attacking():
		_breath -= 1
	_fsm(delta)
	if hitbox_on:
		try_hits()
	apply_gravity(delta)
	move_and_slide()
	_update_slam_circle()
	post_visual(delta)
	if state == State.StanceBroken or state == State.Wakeup:
		set_punish_color()


func _is_attacking() -> bool:
	match state:
		State.Sweep, State.Thrust, State.Slam, State.DoubleSlash1, State.DoubleSlash2:
			return true
		_:
			return false


func _fsm(delta: float) -> void:
	match state:
		State.Idle:
			_st_idle(delta)
		State.Walk:
			_st_walk(delta)
		State.Sweep, State.Thrust, State.Slam, State.DoubleSlash1, State.DoubleSlash2:
			_st_attack(delta)
		State.Hitstun:
			_st_hitstun(delta)
		State.StanceBroken:
			_st_broken(delta)
		State.Wakeup:
			_st_wakeup(delta)
		State.Death:
			_st_death(delta)


func _st_idle(delta: float) -> void:
	state_name = "Idle"
	phase = "—"
	local_frame += 1
	stop_horizontal()
	_turn_to_player(delta, 180.0)
	_ai_decide()


func _st_walk(delta: float) -> void:
	state_name = "Walk"
	phase = "—"
	local_frame += 1
	_turn_to_player(delta, 180.0)
	var d := _dist()
	if d > 2.0:
		apply_horizontal(get_forward(), CombatConsts.ENEMY_WALK_SPEED)
	else:
		stop_horizontal()
	_ai_decide()


func _st_attack(delta: float) -> void:
	local_frame += 1
	tick_attack_events()
	var turning := 180.0
	if phase == "active" or _turn_lock:
		turning = 0.0
	if state == State.Thrust:
		if local_frame == 10:
			_turn_lock = true
			_turn_to_player(delta, 10000.0)
			turning = 0.0
		elif local_frame < 10:
			turning = 180.0
		else:
			turning = 0.0
	if turning > 0.0:
		_turn_to_player(delta, turning)
	if phase == "startup":
		set_telegraph_color()
	if state == State.Slam and local_frame == 8:
		_circle.visible = true
	if state == State.DoubleSlash2 and local_frame <= 10:
		set_telegraph_color()
	if state == State.Thrust:
		if phase == "active":
			apply_horizontal(get_forward(), 1.4 / (8.0 / 60.0))
		else:
			stop_horizontal()
	elif current_attack and current_attack.step_distance > 0.0:
		apply_step_this_frame(current_attack)
	elif phase != "active":
		stop_horizontal()
	if current_attack and local_frame >= current_attack.total:
		if state == State.DoubleSlash1:
			_enter(State.DoubleSlash2)
		else:
			_breath = CombatConsts.BREATH_FRAMES
			_enter(State.Idle)


func _st_hitstun(_delta: float) -> void:
	state_name = "Hitstun"
	local_frame += 1
	_hitstun_left -= 1
	velocity.x = _knock.x
	velocity.z = _knock.z
	_knock *= 0.82
	phase = "getup" if (_getup_at >= 0 and local_frame > _getup_at) else "hitstun"
	if _hitstun_left <= 0:
		_enter(State.Idle)


func _st_broken(_delta: float) -> void:
	state_name = "StanceBroken"
	phase = "kneel"
	local_frame += 1
	stance_broken_left = CombatConsts.STANCE_BROKEN_FRAMES - local_frame
	stop_horizontal()
	set_punish_color()
	if body_mesh:
		body_mesh.rotation_degrees.x = 28.0
		head_mesh.position.y = body_height * 0.62
	if local_frame >= CombatConsts.STANCE_BROKEN_FRAMES:
		_enter(State.Wakeup)


func _st_wakeup(_delta: float) -> void:
	state_name = "Wakeup"
	phase = "wakeup"
	local_frame += 1
	hyperarmor = true
	stop_horizontal()
	if body_mesh:
		body_mesh.rotation_degrees.x = lerpf(body_mesh.rotation_degrees.x, 0.0, 0.15)
	if local_frame >= CombatConsts.WAKEUP_FRAMES:
		hyperarmor_off()
		_enter(State.Idle)


func _st_death(_delta: float) -> void:
	state_name = "Death"
	phase = "death"
	local_frame += 1
	stop_horizontal()
	iframe = true
	if body_mesh:
		body_mesh.rotation_degrees.x = 80.0


func _turn_to_player(delta: float, deg: float) -> void:
	if _player == null:
		return
	turn_towards(_player.global_position, deg, delta)


func _dist() -> float:
	return planar_distance_to(_player)


func distance_band() -> String:
	var d := _dist()
	if d <= 2.2:
		return "Close"
	if d <= 3.5:
		return "Mid"
	if d <= 5.0:
		return "Far"
	return "Out"


func _ai_decide() -> void:
	if _player == null or _player.hp <= 0:
		if state != State.Idle:
			_enter(State.Idle)
		stop_horizontal()
		return
	match state:
		State.Sweep, State.Thrust, State.Slam, State.DoubleSlash1, State.DoubleSlash2, State.Hitstun, State.StanceBroken, State.Wakeup, State.Death:
			return
	var d := _dist()
	if d > 5.0:
		if state != State.Walk:
			_enter(State.Walk)
		return
	if _breath > 0:
		if d > 2.4:
			if state != State.Walk:
				_enter(State.Walk)
		elif state != State.Idle:
			_enter(State.Idle)
		return
	var pick := _pick_attack()
	if pick == &"":
		if d > 2.4:
			if state != State.Walk:
				_enter(State.Walk)
		elif state != State.Idle:
			_enter(State.Idle)
		return
	_commit_attack(pick)


func _pick_attack() -> StringName:
	var band := distance_band()
	var pstate := _player.state_name if _player else ""
	var weights: Dictionary = {}
	if band == "Mid" and not _player.iframe:
		weights[&"Sweep"] = 40
	if band == "Close" and slam_cd > 0:
		weights[&"Sweep"] = int(weights.get(&"Sweep", 0)) + 20
	if band == "Far":
		weights[&"Thrust"] = 35
	if _player is PlayerKnight and (_player as PlayerKnight).frames_since_roll_end <= 20:
		weights[&"Thrust"] = int(weights.get(&"Thrust", 0)) + 25
	if band == "Mid":
		weights[&"Thrust"] = int(weights.get(&"Thrust", 0)) + 10
	if band == "Close" and _player_behind():
		weights.erase(&"Thrust")
	if band == "Close":
		weights[&"Slam"] = 30
		if pstate == "Guard" or (_player is PlayerKnight and (_player as PlayerKnight).is_in_attack_recovery()):
			weights[&"Slam"] = 45
	if band == "Mid":
		weights[&"Slam"] = int(weights.get(&"Slam", 0)) + 15
	if slam_cd > 0:
		weights.erase(&"Slam")
	if thrust_cd > 0:
		weights.erase(&"Thrust")
	if band == "Close" or band == "Mid":
		if pstate == "Guard":
			weights[&"DoubleSlash"] = 40
		elif band == "Close":
			weights[&"DoubleSlash"] = 25
	if band == "Far" or band == "Out":
		weights.erase(&"DoubleSlash")
	if ds_cd > 0:
		weights.erase(&"DoubleSlash")
	var choice := _weighted(weights)
	if choice != &"" and choice == last_attack and choice != &"Sweep":
		choice = _weighted(weights)
	return choice


func _player_behind() -> bool:
	if _player == null:
		return false
	var to := _player.global_position - global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return false
	return get_forward().dot(to.normalized()) < 0.0


func _weighted(weights: Dictionary) -> StringName:
	var total := 0
	for k in weights.keys():
		total += int(weights[k])
	if total <= 0:
		return &""
	var r := randi() % total
	var acc := 0
	for k in weights.keys():
		acc += int(weights[k])
		if r < acc:
			return k
	return &""


func _commit_attack(id: StringName) -> void:
	last_attack = id
	match id:
		&"Sweep":
			_enter(State.Sweep)
		&"Thrust":
			_enter(State.Thrust)
			thrust_cd = 90
		&"Slam":
			_enter(State.Slam)
			slam_cd = 180
		&"DoubleSlash":
			_enter(State.DoubleSlash1)
			ds_cd = 90


func _enter(s: State) -> void:
	var keep_hp := hp
	clear_combat_flags()
	hyperarmor = false
	_turn_lock = false
	if _circle:
		_circle.visible = false
	if body_mesh and s != State.StanceBroken and s != State.Death:
		body_mesh.rotation_degrees.x = 0.0
		head_mesh.position.y = body_height * 0.82
	state = s
	local_frame = 0
	state_name = State.keys()[s]
	current_attack = null
	hp = keep_hp
	match s:
		State.Idle:
			phase = "—"
			clear_phase_color()
			play_pose(&"Idle")
		State.Walk:
			phase = "—"
			clear_phase_color()
			play_pose(&"Walk")
		State.Sweep:
			begin_attack(MoveDB.get_move(&"Sweep"))
			set_telegraph_color()
			play_pose(&"Sweep")
		State.Thrust:
			begin_attack(MoveDB.get_move(&"Thrust"))
			set_telegraph_color()
			play_pose(&"Thrust")
		State.Slam:
			begin_attack(MoveDB.get_move(&"Slam"))
			set_telegraph_color()
			play_pose(&"Slam")
		State.DoubleSlash1:
			begin_attack(MoveDB.get_move(&"DoubleSlash1"))
			set_telegraph_color()
			play_pose(&"DoubleSlash1")
		State.DoubleSlash2:
			begin_attack(MoveDB.get_move(&"DoubleSlash2"))
			set_telegraph_color()
			play_pose(&"DoubleSlash2")
		State.Hitstun:
			phase = "hitstun"
			play_pose(&"Hitstun")
		State.StanceBroken:
			phase = "kneel"
			stance = 0
			stance_broken_left = CombatConsts.STANCE_BROKEN_FRAMES
			stance_break_flash()
			set_punish_color()
			play_pose(&"StanceBroken")
		State.Wakeup:
			phase = "wakeup"
			stance = CombatConsts.WAKEUP_STANCE
			hyperarmor_on()
			play_pose(&"Wakeup")
		State.Death:
			phase = "death"
			hp = 0
			iframe = true
			play_pose(&"Death")
			CombatBus.actor_died.emit(self)


func apply_stance_damage(atk: AttackData) -> int:
	if state == State.StanceBroken or state == State.Death or state == State.Wakeup:
		return 0
	var amt := atk.stance_damage
	if amt <= 0:
		return 0
	stance = maxi(0, stance - amt)
	return amt


func try_stance_break() -> bool:
	if stance > 0:
		return false
	if state == State.StanceBroken or state == State.Death or state == State.Wakeup:
		return false
	_enter(State.StanceBroken)
	return true


func on_stagger(atk: AttackData, attacker: CombatActor) -> void:
	_hitstun_left = atk.hitstun_frames()
	_getup_at = atk.slam_getup_starts_at()
	var k := 3.5
	match atk.hitstun_class:
		AttackData.HitstunClass.HEAVY:
			k = 6.0
		AttackData.HitstunClass.SLAM:
			k = 8.5
		_:
			k = 3.5
	_knock = attacker.get_forward() * k
	_enter(State.Hitstun)


func on_killed(_attacker: CombatActor, _atk: AttackData) -> void:
	_enter(State.Death)


func _update_slam_circle() -> void:
	if _circle == null:
		return
	if state == State.Slam and local_frame >= 8 and local_frame < 41:
		if not _circle.visible:
			_circle.visible = true
			var ap := _circle.get_node_or_null("AnimationPlayer") as AnimationPlayer
			if ap and ap.has_animation(&"Pulse"):
				ap.play(&"Pulse")
		if _circle_mat:
			if local_frame >= 33:
				_circle_mat.albedo_color = Color(CombatConsts.COLOR_ACTIVE, 0.4)
				_circle_mat.emission = CombatConsts.COLOR_ACTIVE
			else:
				_circle_mat.albedo_color = Color(CombatConsts.COLOR_TELEGRAPH, 0.42)
				_circle_mat.emission = CombatConsts.COLOR_TELEGRAPH
	else:
		_circle.visible = false


func reset_to_spawn(pos: Vector3, look: Vector3) -> void:
	global_position = pos
	velocity = Vector3.ZERO
	restore_hp()
	stance = CombatConsts.ENEMY_STANCE
	stance_broken_left = 0
	slam_cd = 0
	thrust_cd = 0
	ds_cd = 0
	_breath = 30
	last_attack = &""
	_knock = Vector3.ZERO
	_circle.visible = false
	if body_mesh:
		body_mesh.rotation_degrees.x = 0.0
	face_dir(look - pos)
	_enter(State.Idle)
