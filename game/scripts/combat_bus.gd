extends Node

signal fight_reset
signal actor_died(actor: Node)
signal hit_landed(info: Dictionary)

var last_damage: int = 0
var last_stance: int = 0
var last_blocked: bool = false
var last_move: StringName = &""
var last_victim: String = ""
var debug_hud_on: bool = true
var debug_wires_on: bool = true


func report_hit(info: Dictionary) -> void:
	last_damage = int(info.get("damage", 0))
	last_stance = int(info.get("stance", 0))
	last_blocked = bool(info.get("blocked", false))
	last_move = info.get("move", &"") as StringName
	last_victim = str(info.get("victim", ""))
	hit_landed.emit(info)


func request_reset() -> void:
	fight_reset.emit()
