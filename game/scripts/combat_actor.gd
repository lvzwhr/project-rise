class_name CombatActor
extends CharacterBody3D

## Shared HP, events, hit test, placeholder mesh, debug wires.
## Child scripts own the state machine.

enum Team { PLAYER, ENEMY }

@export var team: Team = Team.PLAYER

var hp: int = 1
var max_hp: int = 1
var actor_id: String = ""
var body_radius: float = 0.3
var body_height: float = 1.8

var iframe: bool = false
var hyperarmor: bool = false
var can_buffer_flag: bool = false
var hitbox_on: bool = false

var state_name: String = "Idle"
var phase: String = "—"
var local_frame: int = 0
var current_attack: AttackData = null

var flash_frames: int = 0
var gold_flash_frames: int = 0

var _already_hit: Array = []
var _gravity: float = 50.0
var _base_body_color: Color = Color.WHITE
var _base_sword_color: Color = Color.WHITE
var _weapon_phase_color: Color = Color.WHITE
var _using_phase_color: bool = false

var body_mesh: MeshInstance3D
var accent_mesh: MeshInstance3D
var head_mesh: MeshInstance3D
var weapon_pivot: Node3D
var sword_mesh: MeshInstance3D
var hurt_wire: MeshInstance3D
var hit_wire: MeshInstance3D
var anim: AnimationPlayer
var _body_mat: StandardMaterial3D
var _sword_mat: StandardMaterial3D
var _accent_mat: StandardMaterial3D
var _hurt_mat: StandardMaterial3D
var _hit_mat: StandardMaterial3D
var artist_visual: Node3D
var visual_anim: AnimationPlayer
var _has_artist_visual: bool = false
var _hurt_flash_mat: Material
var _iframe_mat: Material
var _hyper_mat: Material


func _ready() -> void:
	add_to_group("combat_actors")
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 50.0))
	floor_snap_length = 0.25
	motion_mode = MOTION_MODE_GROUNDED


func build_rig(p_radius: float, p_height: float, body_color: Color, sword_color: Color, accent_color: Color, bulk: float = 1.0, visual_path: String = "") -> void:
	body_radius = p_radius
	body_height = p_height
	_base_body_color = body_color
	_base_sword_color = sword_color

	collision_layer = CombatConsts.LAYER_PLAYER_BODY if team == Team.PLAYER else CombatConsts.LAYER_ENEMY_BODY
	collision_mask = CombatConsts.LAYER_WORLD | (CombatConsts.LAYER_ENEMY_BODY if team == Team.PLAYER else CombatConsts.LAYER_PLAYER_BODY)

	var cap := CollisionShape3D.new()
	var cap_shape := CapsuleShape3D.new()
	cap_shape.radius = p_radius
	cap_shape.height = p_height
	cap.shape = cap_shape
	cap.position.y = p_height * 0.5
	add_child(cap)

	_body_mat = _make_mat(body_color)
	body_mesh = MeshInstance3D.new()
	var body_c := CapsuleMesh.new()
	body_c.radius = p_radius
	body_c.height = p_height
	body_mesh.mesh = body_c
	body_mesh.material_override = _body_mat
	body_mesh.position.y = p_height * 0.5
	add_child(body_mesh)

	head_mesh = MeshInstance3D.new()
	var head := SphereMesh.new()
	head.radius = p_radius * 0.72
	head.height = p_radius * 1.44
	head_mesh.mesh = head
	head_mesh.material_override = _body_mat
	head_mesh.position = Vector3(0.0, p_height * 0.82, p_radius * 0.35)
	add_child(head_mesh)

	_accent_mat = _make_mat(accent_color)
	accent_mesh = MeshInstance3D.new()
	var pauldron := BoxMesh.new()
	pauldron.size = Vector3(p_radius * 2.4 * bulk, 0.22, 0.38)
	accent_mesh.mesh = pauldron
	accent_mesh.material_override = _accent_mat
	accent_mesh.position = Vector3(0.0, p_height * 0.72, 0.02)
	add_child(accent_mesh)

	weapon_pivot = Node3D.new()
	weapon_pivot.name = "WeaponPivot"
	weapon_pivot.position = Vector3(p_radius + 0.08, p_height * 0.62, 0.05)
	add_child(weapon_pivot)

	_sword_mat = _make_mat(sword_color, 0.15)
	sword_mesh = MeshInstance3D.new()
	var blade := BoxMesh.new()
	blade.size = Vector3(0.07, 0.07, 1.15)
	sword_mesh.mesh = blade
	sword_mesh.position = Vector3(0.0, 0.0, 0.62)
	sword_mesh.material_override = _sword_mat
	weapon_pivot.add_child(sword_mesh)

	var guard := MeshInstance3D.new()
	var gmesh := BoxMesh.new()
	gmesh.size = Vector3(0.22, 0.05, 0.05)
	guard.mesh = gmesh
	guard.material_override = _sword_mat
	guard.position.z = 0.08
	weapon_pivot.add_child(guard)

	var hurt := Area3D.new()
	hurt.name = "Hurtbox"
	hurt.monitoring = false
	hurt.monitorable = true
	hurt.collision_layer = CombatConsts.LAYER_PLAYER_HURT if team == Team.PLAYER else CombatConsts.LAYER_ENEMY_HURT
	hurt.collision_mask = 0
	var hs := CollisionShape3D.new()
	var hshape := CapsuleShape3D.new()
	hshape.radius = p_radius * 1.05
	hshape.height = p_height * 0.95
	hs.shape = hshape
	hs.position.y = p_height * 0.5
	hurt.add_child(hs)
	add_child(hurt)

	_hurt_mat = _wire_mat(Color(0.2, 0.85, 1.0, 0.35))
	hurt_wire = MeshInstance3D.new()
	var hw := CapsuleMesh.new()
	hw.radius = p_radius * 1.05
	hw.height = p_height * 0.95
	hurt_wire.mesh = hw
	hurt_wire.material_override = _hurt_mat
	hurt_wire.position.y = p_height * 0.5
	hurt_wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(hurt_wire)

	_hit_mat = _wire_mat(CombatConsts.COLOR_ACTIVE)
	hit_wire = MeshInstance3D.new()
	hit_wire.material_override = _hit_mat
	hit_wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hit_wire.visible = false
	add_child(hit_wire)

	anim = AnimationPlayer.new()
	anim.name = "AnimationPlayer"
	add_child(anim)
	if visual_path != "":
		attach_artist_visual(visual_path)


func attach_artist_visual(path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var packed := load(path) as PackedScene
	if packed == null:
		return
	var sink := AnimEventSink.new()
	sink.name = "VisualSink"
	add_child(sink)
	var spacer := Node3D.new()
	spacer.name = "VisualSpacer"
	sink.add_child(spacer)
	artist_visual = packed.instantiate() as Node3D
	if artist_visual == null:
		return
	artist_visual.name = "Visual"
	spacer.add_child(artist_visual)
	visual_anim = artist_visual.get_node_or_null("AnimationPlayer") as AnimationPlayer
	_has_artist_visual = true
	if body_mesh:
		body_mesh.visible = false
	if head_mesh:
		head_mesh.visible = false
	if accent_mesh:
		accent_mesh.visible = false
	if weapon_pivot:
		weapon_pivot.visible = false
	if ResourceLoader.exists("res://assets/materials/hurt_flash_white.tres"):
		_hurt_flash_mat = load("res://assets/materials/hurt_flash_white.tres")
	if ResourceLoader.exists("res://assets/materials/iframe_debug_blue.tres"):
		_iframe_mat = load("res://assets/materials/iframe_debug_blue.tres")
	if ResourceLoader.exists("res://assets/materials/hyperarmor_debug_orange.tres"):
		_hyper_mat = load("res://assets/materials/hyperarmor_debug_orange.tres")


func play_pose(clip: StringName) -> void:
	if visual_anim == null:
		return
	if not visual_anim.has_animation(clip):
		return
	if visual_anim.current_animation == String(clip) and visual_anim.is_playing():
		return
	visual_anim.play(clip)


func _artist_meshes() -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if artist_visual == null:
		return out
	var hip := artist_visual.get_node_or_null("Hip")
	var root: Node = artist_visual
	if hip:
		root = hip
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_i := node as MeshInstance3D
		if mesh_i:
			out.append(mesh_i)
	return out


func _set_artist_override(mat: Material) -> void:
	for mesh_i in _artist_meshes():
		mesh_i.material_override = mat


func _make_mat(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.55
	m.metallic = 0.25
	if emission_energy > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission_energy
	return m


func _wire_mat(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = color
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.no_depth_test = false
	return m


func get_forward() -> Vector3:
	return Vector3(sin(rotation.y), 0.0, cos(rotation.y))


func turn_towards(world_pos: Vector3, deg_per_sec: float, delta: float) -> void:
	var to := world_pos - global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return
	var desired := atan2(to.x, to.z)
	if deg_per_sec >= 10000.0:
		rotation.y = desired
		return
	var max_rad := deg_to_rad(deg_per_sec) * delta
	var diff := angle_difference(rotation.y, desired)
	rotation.y += clampf(diff, -max_rad, max_rad)


func face_dir(dir: Vector3) -> void:
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return
	rotation.y = atan2(dir.x, dir.z)


func planar_distance_to(other: Node3D) -> float:
	if other == null:
		return 999.0
	var a := Vector2(global_position.x, global_position.z)
	var b := Vector2(other.global_position.x, other.global_position.z)
	return a.distance_to(b)


func apply_gravity(delta: float) -> void:
	if is_on_floor() and velocity.y < 0.0:
		velocity.y = 0.0
	else:
		velocity.y -= _gravity * delta


func jump_launch() -> void:
	velocity.y = _gravity * (float(CombatConsts.JUMP_RISE_FRAMES) / 60.0)


func clear_combat_flags() -> void:
	hit_off()
	iframe = false
	can_buffer_flag = false
	_already_hit.clear()
	_using_phase_color = false
	_reset_sword_color()


func begin_attack(data: AttackData) -> void:
	current_attack = data
	local_frame = 0
	can_buffer_flag = false
	hit_off()
	_already_hit.clear()
	phase = "startup"


func tick_attack_events() -> void:
	if current_attack == null:
		return
	var a := current_attack
	var f := local_frame
	if a.hit_on > 0 and f == a.hit_on:
		hit_on()
	if a.hit_off > 0 and f == a.hit_off:
		hit_off()
	if a.iframe_on > 0 and f == a.iframe_on:
		iframe_on()
	if a.iframe_off > 0 and f == a.iframe_off:
		iframe_off()
	if a.hyperarmor_on > 0 and f == a.hyperarmor_on:
		hyperarmor_on()
	if a.hyperarmor_off > 0 and f == a.hyperarmor_off:
		hyperarmor_off()
	if a.can_buffer_on > 0 and f == a.can_buffer_on:
		can_buffer()
	if a.can_buffer_off > 0 and f > a.can_buffer_off:
		can_buffer_flag = false
	_refresh_phase()


func _refresh_phase() -> void:
	if current_attack == null:
		return
	var a := current_attack
	if a.startup > 0 and local_frame <= a.startup:
		phase = "startup"
	elif a.hit_on > 0 and local_frame >= a.hit_on and (a.hit_off == 0 or local_frame < a.hit_off):
		phase = "active"
	else:
		phase = "recovery"


func hit_on() -> void:
	hitbox_on = true
	_already_hit.clear()
	_using_phase_color = true
	_set_sword_color(CombatConsts.COLOR_ACTIVE, 1.6)
	_show_hit_wire()
	try_hits()


func hit_off() -> void:
	hitbox_on = false
	if hit_wire:
		hit_wire.visible = false
	if current_attack and current_attack.punish_green_rec == 1:
		_using_phase_color = true
		_set_sword_color(CombatConsts.COLOR_PUNISH, 0.8)
	elif _using_phase_color:
		_reset_sword_color()
		_using_phase_color = false


func iframe_on() -> void:
	iframe = true


func iframe_off() -> void:
	iframe = false


func hyperarmor_on() -> void:
	hyperarmor = true


func hyperarmor_off() -> void:
	hyperarmor = false


func can_buffer() -> void:
	can_buffer_flag = true


func try_hits() -> void:
	if not hitbox_on or current_attack == null:
		return
	for node in get_tree().get_nodes_in_group("combat_actors"):
		var other := node as CombatActor
		if other == null or other == self:
			continue
		if other in _already_hit:
			continue
		if other.hp <= 0:
			continue
		if _shape_hits(other, current_attack):
			_already_hit.append(other)
			other.receive_hit(self, current_attack)


func _shape_hits(target: CombatActor, atk: AttackData) -> bool:
	if atk.hit_shape == AttackData.HitShape.NONE:
		return false
	var origin := global_position
	var tpos := target.global_position
	var planar := Vector3(tpos.x - origin.x, 0.0, tpos.z - origin.z)
	var dist := planar.length()
	var target_feet := tpos.y
	var target_head := tpos.y + target.body_height
	if target_head < origin.y + atk.height_min - 0.25:
		return false
	if target_feet > origin.y + atk.height_max + 0.35:
		return false
	var radius_slop := target.body_radius
	match atk.hit_shape:
		AttackData.HitShape.CYLINDER:
			return dist <= atk.reach + radius_slop
		AttackData.HitShape.CAPSULE:
			var fwd := get_forward()
			var along := planar.dot(fwd)
			if along < -radius_slop or along > atk.reach + radius_slop:
				return false
			var perp := (planar - fwd * along).length()
			return perp <= atk.capsule_radius + radius_slop
		AttackData.HitShape.ARC:
			if dist > atk.reach + radius_slop:
				return false
			if dist < 0.08:
				return true
			var ang := rad_to_deg(get_forward().angle_to(planar.normalized()))
			return ang <= atk.arc_deg * 0.5 + 4.0
		_:
			return false


func is_in_front_of_me(other: Node3D) -> bool:
	var to := other.global_position - global_position
	to.y = 0.0
	if to.length_squared() < 0.0001:
		return true
	return get_forward().dot(to.normalized()) >= CombatConsts.GUARD_ARC_DOT


func receive_hit(attacker: CombatActor, atk: AttackData) -> void:
	if hp <= 0:
		return
	if iframe:
		return
	if handle_block(attacker, atk):
		_hurt_flash()
		return
	hp = maxi(0, hp - atk.damage)
	_hurt_flash()
	var stance_amt := apply_stance_damage(atk)
	CombatBus.report_hit({
		"damage": atk.damage,
		"stance": stance_amt,
		"blocked": false,
		"move": atk.move_id,
		"victim": actor_id,
	})
	if hp <= 0:
		on_killed(attacker, atk)
		return
	if try_stance_break():
		return
	if hyperarmor:
		return
	on_stagger(atk, attacker)


func handle_block(_attacker: CombatActor, _atk: AttackData) -> bool:
	return false


func apply_stance_damage(_atk: AttackData) -> int:
	return 0


func try_stance_break() -> bool:
	return false


func on_stagger(_atk: AttackData, _attacker: CombatActor) -> void:
	pass


func on_killed(_attacker: CombatActor, _atk: AttackData) -> void:
	pass


func _hurt_flash() -> void:
	flash_frames = 1


func stance_break_flash() -> void:
	gold_flash_frames = 1


func apply_horizontal(dir: Vector3, speed: float) -> void:
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		velocity.x = 0.0
		velocity.z = 0.0
		return
	dir = dir.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed


func stop_horizontal() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func apply_step_this_frame(data: AttackData) -> void:
	if data == null or data.step_distance <= 0.0 or data.total <= 0:
		return
	var frames := maxi(1, data.startup + data.active)
	var speed := data.step_distance / (float(frames) / 60.0)
	if local_frame <= frames:
		var d := get_forward()
		velocity.x = d.x * speed
		velocity.z = d.z * speed
	else:
		stop_horizontal()


func post_visual(delta: float) -> void:
	_update_wires()
	_update_placeholder_pose(delta)
	_update_punish_green()
	_apply_flash_materials()
	if flash_frames > 0:
		flash_frames -= 1
	if gold_flash_frames > 0:
		gold_flash_frames -= 1


func _update_punish_green() -> void:
	if current_attack == null or not hitbox_on:
		pass
	if current_attack == null or current_attack.punish_green_rec <= 0:
		return
	if phase != "recovery":
		return
	var rec_frame := local_frame - current_attack.startup - current_attack.active
	if rec_frame >= current_attack.punish_green_rec:
		_using_phase_color = true
		_set_sword_color(CombatConsts.COLOR_PUNISH, 0.9)


func set_telegraph_color() -> void:
	_using_phase_color = true
	_set_sword_color(CombatConsts.COLOR_TELEGRAPH, 1.4)


func set_punish_color() -> void:
	_using_phase_color = true
	_set_sword_color(CombatConsts.COLOR_PUNISH, 0.9)


func clear_phase_color() -> void:
	_using_phase_color = false
	_reset_sword_color()


func _set_sword_color(color: Color, emission: float) -> void:
	if _sword_mat == null:
		return
	_sword_mat.albedo_color = color
	_sword_mat.emission_enabled = true
	_sword_mat.emission = color
	_sword_mat.emission_energy_multiplier = emission


func _reset_sword_color() -> void:
	if _sword_mat == null:
		return
	_sword_mat.albedo_color = _base_sword_color
	_sword_mat.emission_enabled = true
	_sword_mat.emission = _base_sword_color
	_sword_mat.emission_energy_multiplier = 0.12


func _apply_flash_materials() -> void:
	if _has_artist_visual:
		if gold_flash_frames > 0:
			_set_artist_override(_hurt_flash_mat)
		elif flash_frames > 0:
			_set_artist_override(_hurt_flash_mat)
		elif iframe and _iframe_mat:
			_set_artist_override(_iframe_mat)
		elif hyperarmor and _hyper_mat:
			_set_artist_override(_hyper_mat)
		else:
			_set_artist_override(null)
		return
	if _body_mat == null:
		return
	if gold_flash_frames > 0:
		_body_mat.albedo_color = CombatConsts.COLOR_STANCE_GOLD
		_body_mat.emission_enabled = true
		_body_mat.emission = CombatConsts.COLOR_STANCE_GOLD
		_body_mat.emission_energy_multiplier = 2.0
		return
	if flash_frames > 0:
		_body_mat.albedo_color = CombatConsts.COLOR_FLASH
		_body_mat.emission_enabled = true
		_body_mat.emission = CombatConsts.COLOR_FLASH
		_body_mat.emission_energy_multiplier = 3.0
		return
	var tint := _base_body_color
	if iframe:
		tint = tint.lerp(CombatConsts.COLOR_IFRAME, 0.55)
	elif hyperarmor:
		tint = tint.lerp(CombatConsts.COLOR_HYPERARMOR, 0.4)
	_body_mat.albedo_color = tint
	_body_mat.emission_enabled = iframe or hyperarmor
	_body_mat.emission = tint
	_body_mat.emission_energy_multiplier = 0.55 if (iframe or hyperarmor) else 0.0


func _show_hit_wire() -> void:
	if hit_wire == null or current_attack == null:
		return
	var atk := current_attack
	match atk.hit_shape:
		AttackData.HitShape.CYLINDER:
			var cyl := CylinderMesh.new()
			cyl.top_radius = atk.reach
			cyl.bottom_radius = atk.reach
			cyl.height = maxf(0.2, atk.height_max - atk.height_min)
			hit_wire.mesh = cyl
			hit_wire.position = Vector3(0, (atk.height_min + atk.height_max) * 0.5, 0)
			hit_wire.rotation = Vector3.ZERO
		AttackData.HitShape.CAPSULE:
			var cap := CapsuleMesh.new()
			cap.radius = atk.capsule_radius
			cap.height = atk.reach
			hit_wire.mesh = cap
			hit_wire.position = Vector3(0, (atk.height_min + atk.height_max) * 0.5, atk.reach * 0.5)
			hit_wire.rotation_degrees = Vector3(90, 0, 0)
		AttackData.HitShape.ARC:
			var cyl2 := CylinderMesh.new()
			cyl2.top_radius = atk.reach
			cyl2.bottom_radius = atk.reach
			cyl2.height = maxf(0.15, atk.height_max - atk.height_min)
			hit_wire.mesh = cyl2
			hit_wire.position = Vector3(0, (atk.height_min + atk.height_max) * 0.5, 0)
			hit_wire.rotation = Vector3.ZERO
		_:
			hit_wire.mesh = null
	hit_wire.visible = CombatBus.debug_wires_on


func _update_wires() -> void:
	if hurt_wire:
		hurt_wire.visible = CombatBus.debug_wires_on
	if hit_wire:
		if hitbox_on and CombatBus.debug_wires_on:
			hit_wire.visible = true
			if _hit_mat:
				_hit_mat.albedo_color = Color(CombatConsts.COLOR_ACTIVE, 0.28)
		else:
			hit_wire.visible = false


func _update_placeholder_pose(_delta: float) -> void:
	if _has_artist_visual:
		return
	if weapon_pivot == null:
		return
	var rest := Vector3(deg_to_rad(-70), deg_to_rad(12), deg_to_rad(-18))
	var target := rest
	var t := 0.0
	if current_attack and current_attack.total > 0:
		t = clampf(float(local_frame) / float(current_attack.total), 0.0, 1.0)
	match state_name:
		"Light1":
			target = _swing_pose(Vector3(deg_to_rad(-20), deg_to_rad(95), 0), Vector3(deg_to_rad(-10), deg_to_rad(-100), 0), t)
		"Light2":
			target = _swing_pose(Vector3(deg_to_rad(-20), deg_to_rad(-95), 0), Vector3(deg_to_rad(-10), deg_to_rad(100), 0), t)
		"Light3":
			target = _swing_pose(Vector3(deg_to_rad(-140), 0, 0), Vector3(deg_to_rad(30), deg_to_rad(-20), 0), t)
		"Heavy", "ChargedHeavy":
			target = _swing_pose(Vector3(deg_to_rad(-150), deg_to_rad(40), 0), Vector3(deg_to_rad(25), deg_to_rad(-70), 0), t)
		"JumpAttack", "RunningAttack":
			target = _swing_pose(Vector3(deg_to_rad(-90), 0, 0), Vector3(deg_to_rad(20), 0, 0), t)
		"Riposte":
			target = _swing_pose(Vector3(deg_to_rad(-30), 0, 0), Vector3(deg_to_rad(10), 0, deg_to_rad(10)), t)
		"DodgeRoll":
			target = rest + Vector3(deg_to_rad(-40), 0, 0)
		"Guard", "GuardHit":
			target = Vector3(deg_to_rad(-20), deg_to_rad(70), deg_to_rad(40))
		"Sweep":
			target = _swing_pose(Vector3(deg_to_rad(-15), deg_to_rad(110), deg_to_rad(15)), Vector3(deg_to_rad(-10), deg_to_rad(-120), 0), t)
		"Thrust":
			target = _swing_pose(Vector3(deg_to_rad(-5), 0, 0), Vector3(deg_to_rad(5), 0, 0), t)
			weapon_pivot.position.z = 0.05 + (0.9 if phase == "active" else 0.15)
		"Slam":
			target = _swing_pose(Vector3(deg_to_rad(-170), 0, 0), Vector3(deg_to_rad(40), 0, 0), t)
		"DoubleSlash1":
			target = _swing_pose(Vector3(deg_to_rad(-100), deg_to_rad(80), 0), Vector3(deg_to_rad(20), deg_to_rad(-40), 0), t)
		"DoubleSlash2":
			target = _swing_pose(Vector3(deg_to_rad(-40), deg_to_rad(-80), 0), Vector3(deg_to_rad(-10), deg_to_rad(100), 0), t)
		"StanceBroken":
			target = Vector3(deg_to_rad(50), 0, deg_to_rad(30))
		"Exhaust", "GuardBreak":
			target = Vector3(deg_to_rad(-40), 0, deg_to_rad(25))
		"Hitstun":
			target = rest + Vector3(deg_to_rad(25), deg_to_rad(-20), 0)
		"Death":
			target = Vector3(deg_to_rad(80), 0, 0)
		_:
			weapon_pivot.position.z = 0.05
	if state_name != "Thrust":
		weapon_pivot.position.z = 0.05
	weapon_pivot.rotation = weapon_pivot.rotation.lerp(target, 0.35)


func _swing_pose(from: Vector3, to: Vector3, t: float) -> Vector3:
	var k := clampf(t * 1.6, 0.0, 1.0)
	if phase == "startup":
		k = clampf(float(local_frame) / maxf(1.0, float(current_attack.startup if current_attack else 10)), 0, 1) * 0.55
		return from * (0.3 + k)
	if phase == "active":
		return from.lerp(to, 0.7)
	return to


func restore_hp() -> void:
	hp = max_hp
	iframe = false
	hyperarmor = false
	can_buffer_flag = false
	hit_off()
	flash_frames = 0
	clear_phase_color()
	state_name = "Idle"
	phase = "—"
	local_frame = 0
	current_attack = null
