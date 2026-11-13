class_name DebugHUD
extends CanvasLayer

var player: PlayerKnight
var enemy: EnemyKnight

var _root: Control
var _player_lbl: Label
var _enemy_lbl: Label
var _hit_lbl: Label
var _help_lbl: Label


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_player_lbl = _make_label(Vector2(16, 12), Vector2(560, 280), Color(0.08, 0.10, 0.14, 0.72))
	_enemy_lbl = _make_label(Vector2(1920 - 16 - 560, 12), Vector2(560, 300), Color(0.14, 0.08, 0.08, 0.72))
	_enemy_lbl.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_enemy_lbl.offset_left = -576
	_enemy_lbl.offset_right = -16
	_enemy_lbl.offset_top = 12
	_enemy_lbl.offset_bottom = 320
	_hit_lbl = _make_label(Vector2(16, 1080 - 140), Vector2(720, 88), Color(0.08, 0.08, 0.08, 0.65))
	_hit_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_hit_lbl.offset_left = 16
	_hit_lbl.offset_right = 736
	_hit_lbl.offset_top = -140
	_hit_lbl.offset_bottom = -52
	_help_lbl = _make_label(Vector2(16, 1080 - 48), Vector2(1200, 32), Color(0, 0, 0, 0.0))
	_help_lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_help_lbl.offset_left = 16
	_help_lbl.offset_right = 1216
	_help_lbl.offset_top = -44
	_help_lbl.offset_bottom = -12


func _make_label(pos: Vector2, size: Vector2, bg: Color) -> Label:
	var panel := Panel.new()
	panel.position = pos
	panel.size = size
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.corner_radius_top_left = 6
	sb.corner_radius_top_right = 6
	sb.corner_radius_bottom_left = 6
	sb.corner_radius_bottom_right = 6
	sb.content_margin_left = 12
	sb.content_margin_top = 8
	sb.content_margin_right = 12
	sb.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", sb)
	_root.add_child(panel)
	var lbl := Label.new()
	lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 0.96))
	panel.add_child(lbl)
	return lbl


func _process(_delta: float) -> void:
	visible = CombatBus.debug_hud_on
	if not visible or player == null or enemy == null:
		return
	var lock_d := player.lock_distance()
	var lock_s := ("%.1f m" % lock_d) if lock_d >= 0.0 else "off"
	_player_lbl.text = "PLAYER\nHP %d / %d\nStamina %d / 100   regen-delay %df\nState %s   phase %s   frame %d\niframe %s   hyperarmor %s   can_buffer %s\nLock-on %s" % [
		player.hp,
		player.max_hp,
		int(round(player.stamina)),
		player.regen_delay,
		player.state_name,
		player.phase,
		player.local_frame,
		_lamp(player.iframe, "ON", "off"),
		_lamp(player.hyperarmor, "ON", "off"),
		_lamp(player.can_buffer_flag, "ON", "off"),
		lock_s,
	]
	_enemy_lbl.text = "ENEMY KNIGHT\nHP %d / %d\nStance %d / 100\nState / attack %s   phase %s   frame %d\nhyperarmor %s   StanceBroken %s\nBand %s   dist %.1f m\nCD Slam %df  Thrust %df  DoubleSlash %df" % [
		enemy.hp,
		enemy.max_hp,
		enemy.stance,
		enemy.state_name,
		enemy.phase,
		enemy.local_frame,
		_lamp(enemy.hyperarmor, "ON", "off"),
		("%df" % maxi(enemy.stance_broken_left, 0)) if enemy.state_name == "StanceBroken" else "—",
		enemy.distance_band(),
		enemy.planar_distance_to(player),
		enemy.slam_cd,
		enemy.thrust_cd,
		enemy.ds_cd,
	]
	var blocked := "BLOCKED" if CombatBus.last_blocked else "HIT"
	_hit_lbl.text = "Last: %s  %s  dmg %d  stance %d   wires %s" % [
		CombatBus.last_move,
		blocked if str(CombatBus.last_victim) != "" else "—",
		CombatBus.last_damage,
		CombatBus.last_stance,
		"ON" if CombatBus.debug_wires_on else "off",
	]
	_help_lbl.text = "F1 HUD   F2 hitbox wires   F3 / R reset   Esc / Tab mouse   LMB light  RMB heavy  Space roll  Shift run  Ctrl/Q guard  V jump  C/MMB lock"


func _lamp(on: bool, on_s: String, off_s: String) -> String:
	return on_s if on else off_s
