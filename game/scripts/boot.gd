extends Node

## Builds the frozen input map at boot so project.godot does not need serialized events.


func _ready() -> void:
	Engine.max_fps = 60
	Engine.physics_ticks_per_second = 60
	_setup_input()


func _setup_input() -> void:
	_action("move_left", [KEY_A], [], JOY_AXIS_LEFT_X, -1.0)
	_action("move_right", [KEY_D], [], JOY_AXIS_LEFT_X, 1.0)
	_action("move_forward", [KEY_W], [], JOY_AXIS_LEFT_Y, -1.0)
	_action("move_back", [KEY_S], [], JOY_AXIS_LEFT_Y, 1.0)
	_action("light", [], [MOUSE_BUTTON_LEFT], -1, 0.0, [JOY_BUTTON_X])
	_action("heavy", [], [MOUSE_BUTTON_RIGHT], -1, 0.0, [JOY_BUTTON_Y])
	_action("roll", [KEY_SPACE], [], -1, 0.0, [JOY_BUTTON_B])
	_action("run", [KEY_SHIFT], [], -1, 0.0, [JOY_BUTTON_B])
	_action("guard", [KEY_CTRL, KEY_Q], [], JOY_AXIS_TRIGGER_LEFT, 1.0)
	_action("jump", [KEY_V], [], -1, 0.0, [JOY_BUTTON_A])
	_action("lock_on", [KEY_C], [MOUSE_BUTTON_MIDDLE], -1, 0.0, [JOY_BUTTON_RIGHT_STICK])
	_action("debug_hud", [KEY_F1])
	_action("debug_wires", [KEY_F2])
	_action("debug_reset", [KEY_F3, KEY_R])
	_action("toggle_mouse", [KEY_ESCAPE, KEY_TAB])


func _action(
		name: StringName,
		keys: Array = [],
		mouse_buttons: Array = [],
		axis: int = -1,
		axis_value: float = 0.0,
		joy_buttons: Array = []
	) -> void:
	if not InputMap.has_action(name):
		InputMap.add_action(name, 0.2)
	for kc in keys:
		var ek := InputEventKey.new()
		ek.physical_keycode = kc
		InputMap.action_add_event(name, ek)
	for mb in mouse_buttons:
		var em := InputEventMouseButton.new()
		em.button_index = mb
		InputMap.action_add_event(name, em)
	for jb in joy_buttons:
		var ej := InputEventJoypadButton.new()
		ej.button_index = jb
		InputMap.action_add_event(name, ej)
	if axis >= 0:
		var jm := InputEventJoypadMotion.new()
		jm.axis = axis
		jm.axis_value = axis_value
		InputMap.action_add_event(name, jm)
