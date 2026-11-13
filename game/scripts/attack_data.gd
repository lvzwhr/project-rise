class_name AttackData
extends Resource

enum HitstunClass { LIGHT, HEAVY, SLAM, NONE }
enum HitShape { ARC, CAPSULE, CYLINDER, NONE }

@export var move_id: StringName = &""
@export var stamina_cost: int = 0
@export var startup: int = 0
@export var active: int = 0
@export var recovery: int = 0
@export var total: int = 0
@export var damage: int = 0
@export var stance_damage: int = 0
@export var hitstun_class: HitstunClass = HitstunClass.NONE
@export var block_stamina: int = 0
@export var reach: float = 1.6
@export var arc_deg: float = 90.0
@export var capsule_radius: float = 0.35
@export var height_min: float = 0.4
@export var height_max: float = 1.8
@export var step_distance: float = 0.0
@export var hit_shape: HitShape = HitShape.ARC
@export var hit_on: int = 0
@export var hit_off: int = 0
@export var iframe_on: int = 0
@export var iframe_off: int = 0
@export var hyperarmor_on: int = 0
@export var hyperarmor_off: int = 0
## Local frame when can_buffer turns on. 0 = never.
@export var can_buffer_on: int = 0
@export var can_buffer_off: int = 0
## Recovery-local frame when punish green starts. 1 = entire recovery. 0 = never.
@export var punish_green_rec: int = 0
@export var notes: String = ""


func hitstun_frames() -> int:
	match hitstun_class:
		HitstunClass.LIGHT:
			return CombatConsts.HITSTUN_LIGHT
		HitstunClass.HEAVY:
			return CombatConsts.HITSTUN_HEAVY
		HitstunClass.SLAM:
			return CombatConsts.HITSTUN_SLAM + CombatConsts.HITSTUN_GETUP
		_:
			return 0


func slam_getup_starts_at() -> int:
	if hitstun_class == HitstunClass.SLAM:
		return CombatConsts.HITSTUN_SLAM
	return -1
