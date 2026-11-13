extends Node

## Frozen AttackData for every v1 move. Numbers from player-moveset.md and enemy-knight.md.

var moves: Dictionary = {}


func _ready() -> void:
	moves = {
		&"Light1": _mk(&"Light1", 13, 10, 6, 18, 34, 80, 18, AttackData.HitstunClass.LIGHT, 22, 1.6, 90.0, 0.35, 0.4, 1.8, 0.0, AttackData.HitShape.ARC, 11, 17, 0, 0, 0, 0, 27, 34, 0),
		&"Light2": _mk(&"Light2", 13, 11, 6, 20, 37, 85, 20, AttackData.HitstunClass.LIGHT, 22, 1.6, 90.0, 0.35, 0.4, 1.8, 0.0, AttackData.HitShape.ARC, 12, 18, 0, 0, 0, 0, 30, 37, 0),
		&"Light3": _mk(&"Light3", 16, 14, 8, 28, 50, 110, 26, AttackData.HitstunClass.LIGHT, 22, 1.8, 90.0, 0.35, 0.4, 1.9, 0.4, AttackData.HitShape.ARC, 15, 23, 0, 0, 0, 0, 41, 50, 0),
		&"Heavy": _mk(&"Heavy", 24, 22, 8, 32, 62, 155, 36, AttackData.HitstunClass.HEAVY, 28, 1.7, 110.0, 0.4, 0.3, 1.9, 0.5, AttackData.HitShape.ARC, 23, 31, 0, 0, 16, 31, 53, 62, 0),
		&"ChargedHeavy": _mk(&"ChargedHeavy", 36, 6, 10, 36, 52, 250, 58, AttackData.HitstunClass.SLAM, 40, 1.8, 80.0, 0.45, 0.2, 2.0, 0.7, AttackData.HitShape.ARC, 7, 17, 0, 0, 0, 17, 41, 52, 0),
		&"JumpAttack": _mk(&"JumpAttack", 14, 12, 8, 24, 44, 140, 32, AttackData.HitstunClass.HEAVY, 28, 1.6, 70.0, 0.4, 0.0, 1.8, 0.6, AttackData.HitShape.ARC, 13, 21, 0, 0, 0, 0, 0, 0, 0),
		&"RunningAttack": _mk(&"RunningAttack", 18, 13, 8, 24, 45, 120, 24, AttackData.HitstunClass.HEAVY, 28, 1.9, 50.0, 0.35, 0.4, 1.7, 1.2, AttackData.HitShape.CAPSULE, 14, 22, 0, 0, 0, 0, 38, 45, 0),
		&"DodgeRoll": _mk(&"DodgeRoll", 20, 3, 0, 16, 32, 0, 0, AttackData.HitstunClass.NONE, 0, 0.0, 0.0, 0.0, 0.0, 0.0, 4.2, AttackData.HitShape.NONE, 0, 0, 4, 17, 0, 0, 25, 32, 0),
		&"Riposte": _mk(&"Riposte", 0, 16, 4, 28, 48, 380, 0, AttackData.HitstunClass.NONE, 0, 2.2, 40.0, 0.3, 0.4, 1.6, 0.8, AttackData.HitShape.CAPSULE, 17, 21, 0, 0, 1, 48, 41, 48, 0),
		&"Sweep": _mk(&"Sweep", 0, 22, 10, 28, 60, 130, 0, AttackData.HitstunClass.LIGHT, 22, 2.2, 180.0, 0.4, 0.8, 1.6, 0.0, AttackData.HitShape.ARC, 23, 33, 0, 0, 0, 0, 0, 0, 8),
		&"Thrust": _mk(&"Thrust", 0, 18, 8, 34, 60, 150, 0, AttackData.HitstunClass.HEAVY, 32, 2.8, 30.0, 0.45, 0.6, 1.6, 1.4, AttackData.HitShape.CAPSULE, 19, 27, 0, 0, 0, 0, 0, 0, 6),
		&"Slam": _mk(&"Slam", 0, 32, 8, 40, 80, 210, 0, AttackData.HitstunClass.SLAM, 48, 1.8, 360.0, 1.8, 0.0, 1.2, 0.4, AttackData.HitShape.CYLINDER, 33, 41, 0, 0, 12, 41, 0, 0, 1),
		&"DoubleSlash1": _mk(&"DoubleSlash1", 0, 16, 7, 0, 24, 90, 0, AttackData.HitstunClass.LIGHT, 22, 2.0, 90.0, 0.4, 0.5, 1.8, 0.15, AttackData.HitShape.ARC, 17, 24, 0, 0, 0, 0, 0, 0, 0),
		&"DoubleSlash2": _mk(&"DoubleSlash2", 0, 10, 8, 26, 44, 100, 0, AttackData.HitstunClass.LIGHT, 22, 2.0, 90.0, 0.4, 0.5, 1.8, 0.15, AttackData.HitShape.ARC, 11, 19, 0, 0, 0, 0, 0, 0, 8),
	}


func get_move(id: StringName) -> AttackData:
	return moves[id]


func _mk(
		move_id: StringName,
		stamina_cost: int,
		startup: int,
		active: int,
		recovery: int,
		total: int,
		damage: int,
		stance_damage: int,
		hitstun_class: AttackData.HitstunClass,
		block_stamina: int,
		reach: float,
		arc_deg: float,
		capsule_radius: float,
		height_min: float,
		height_max: float,
		step_distance: float,
		hit_shape: AttackData.HitShape,
		hit_on: int,
		hit_off: int,
		iframe_on: int,
		iframe_off: int,
		hyperarmor_on: int,
		hyperarmor_off: int,
		can_buffer_on: int,
		can_buffer_off: int,
		punish_green_rec: int
	) -> AttackData:
	var a := AttackData.new()
	a.move_id = move_id
	a.stamina_cost = stamina_cost
	a.startup = startup
	a.active = active
	a.recovery = recovery
	a.total = total
	a.damage = damage
	a.stance_damage = stance_damage
	a.hitstun_class = hitstun_class
	a.block_stamina = block_stamina
	a.reach = reach
	a.arc_deg = arc_deg
	a.capsule_radius = capsule_radius
	a.height_min = height_min
	a.height_max = height_max
	a.step_distance = step_distance
	a.hit_shape = hit_shape
	a.hit_on = hit_on
	a.hit_off = hit_off
	a.iframe_on = iframe_on
	a.iframe_off = iframe_off
	a.hyperarmor_on = hyperarmor_on
	a.hyperarmor_off = hyperarmor_off
	a.can_buffer_on = can_buffer_on
	a.can_buffer_off = can_buffer_off
	a.punish_green_rec = punish_green_rec
	return a
