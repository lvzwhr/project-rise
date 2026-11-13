class_name CombatConsts
extends Object

## Frozen combat constants from docs/design. Do not invent replacements.

const FPS := 60
const FRAME_TIME := 1.0 / 60.0

const PLAYER_HP := 1000
const PLAYER_STAMINA := 100.0
const ENEMY_HP := 900
const ENEMY_STANCE := 100
const WAKEUP_STANCE := 40

const STAMINA_REGEN_PER_SEC := 40.0
const STAMINA_REGEN_DELAY_FRAMES := 18
const SPRINT_DRAIN_PER_SEC := 12.0
const SPRINT_FREE_FRAMES := 20
const SPRINT_STUMBLE_FRAMES := 12
const EXHAUST_FRAMES := 48
const GUARD_BREAK_FRAMES := 50
const BUFFER_MEMORY_FRAMES := 10

const WALK_SPEED := 3.2
const RUN_SPEED := 6.2
const ENEMY_WALK_SPEED := 3.0
const STICK_WALK := 0.2
const STICK_RUN := 0.85
const STICK_RUN_HOLD_FRAMES := 10
const LOCK_ACQUIRE := 14.0
const LOCK_DROP := 16.0

const GUARD_RAISE_FRAMES := 4
const GUARD_LOWER_FRAMES := 8
const GUARD_HIT_FRAMES := 10
const GUARD_ROLL_DROP_FRAMES := 4
const GUARD_ARC_DOT := 0.0 ## front 180°: facing·to_hit >= 0

const JUMP_RISE_FRAMES := 10
const JUMP_FALL_FRAMES := 16
const JUMP_LAND_FRAMES := 6
const JUMP_STAMINA := 8
const JUMP_ATTACK_WINDOW_START := 8

const RIPOSTE_RANGE := 2.2
const STANCE_BROKEN_FRAMES := 90
const WAKEUP_FRAMES := 24
const DEATH_RESET_SEC := 2.0
const BREATH_FRAMES := 45

const HITSTUN_LIGHT := 18
const HITSTUN_HEAVY := 26
const HITSTUN_SLAM := 34
const HITSTUN_GETUP := 8

const CHARGE_MIN := 20
const CHARGE_MAX := 48
const CHARGE_WALK := 0.8
const CHARGE_TURN_DEG := 90.0

const ROLL_DISTANCE := 4.2
const ROLL_FRAMES := 32

const ARENA_RADIUS := 10.0

const LAYER_WORLD := 1
const LAYER_PLAYER_BODY := 2
const LAYER_ENEMY_BODY := 4
const LAYER_PLAYER_HIT := 8
const LAYER_ENEMY_HIT := 16
const LAYER_PLAYER_HURT := 32
const LAYER_ENEMY_HURT := 64

const COLOR_TELEGRAPH := Color("#E03030")
const COLOR_ACTIVE := Color("#F0D030")
const COLOR_PUNISH := Color("#30C060")
const COLOR_IFRAME := Color("#40A0FF")
const COLOR_HYPERARMOR := Color("#E07020")
const COLOR_PLAYER := Color("#6A8498")
const COLOR_PLAYER_SWORD := Color("#B8C8D4")
const COLOR_ENEMY := Color("#2A2424")
const COLOR_ENEMY_ACCENT := Color("#8A2020")
const COLOR_ENEMY_SWORD := Color("#5A5050")
const COLOR_FLASH := Color(1, 1, 1, 1)
const COLOR_STANCE_GOLD := Color("#E8C040")
