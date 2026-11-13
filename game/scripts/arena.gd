extends Node3D

const PLAYER_SPAWN := Vector3(0.0, 0.05, 5.2)
const ENEMY_SPAWN := Vector3(0.0, 0.05, -5.2)

var player: PlayerKnight
var enemy: EnemyKnight
var camera: CameraRig
var hud: DebugHUD
var _reset_left: float = -1.0


func _ready() -> void:
	randomize()
	_build_world()
	player = PlayerKnight.new()
	player.name = "Player"
	add_child(player)
	player.global_position = PLAYER_SPAWN
	enemy = EnemyKnight.new()
	enemy.name = "EnemyKnight"
	add_child(enemy)
	enemy.global_position = ENEMY_SPAWN
	camera = CameraRig.new()
	camera.name = "CameraRig"
	add_child(camera)
	camera.player = player
	camera.yaw = PI
	hud = DebugHUD.new()
	hud.name = "DebugHUD"
	add_child(hud)
	hud.player = player
	hud.enemy = enemy
	player.bind_world(camera, enemy)
	enemy.bind_world(player)
	player.face_dir(ENEMY_SPAWN - PLAYER_SPAWN)
	enemy.face_dir(PLAYER_SPAWN - ENEMY_SPAWN)
	CombatBus.actor_died.connect(_on_died)
	CombatBus.fight_reset.connect(reset_fight)
	if DisplayServer.get_name() != "headless":
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().debug_collisions_hint = CombatBus.debug_wires_on


func _physics_process(delta: float) -> void:
	if _reset_left >= 0.0:
		_reset_left -= delta
		if _reset_left <= 0.0:
			_reset_left = -1.0
			reset_fight()


func _on_died(_actor: Node) -> void:
	if _reset_left < 0.0:
		_reset_left = CombatConsts.DEATH_RESET_SEC


func reset_fight() -> void:
	_reset_left = -1.0
	CombatBus.last_damage = 0
	CombatBus.last_stance = 0
	CombatBus.last_blocked = false
	CombatBus.last_move = &""
	CombatBus.last_victim = ""
	player.reset_to_spawn(PLAYER_SPAWN, ENEMY_SPAWN)
	enemy.reset_to_spawn(ENEMY_SPAWN, PLAYER_SPAWN)


func _build_world() -> void:
	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.14, 0.16, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.42, 0.44, 0.48)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.glow_enabled = false
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 35, 0)
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	add_child(sun)

	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, -140, 0)
	fill.light_energy = 0.25
	fill.light_color = Color(0.7, 0.78, 0.9)
	add_child(fill)

	var floor_mat: Material
	if ResourceLoader.exists("res://assets/materials/arena_floor.tres"):
		floor_mat = load("res://assets/materials/arena_floor.tres") as Material
	else:
		var sm := StandardMaterial3D.new()
		sm.albedo_color = Color(0.28, 0.29, 0.30)
		sm.roughness = 0.9
		floor_mat = sm
	var floor := CSGCylinder3D.new()
	floor.radius = CombatConsts.ARENA_RADIUS
	floor.height = 0.5
	floor.sides = 48
	floor.position.y = -0.25
	floor.use_collision = true
	floor.collision_layer = CombatConsts.LAYER_WORLD
	floor.collision_mask = 0
	floor.material = floor_mat
	add_child(floor)

	var ring := CSGCylinder3D.new()
	ring.radius = 3.5
	ring.height = 0.04
	ring.sides = 32
	ring.position.y = 0.01
	var ring_mat := StandardMaterial3D.new()
	ring_mat.albedo_color = Color(0.22, 0.23, 0.24)
	ring.material = ring_mat
	add_child(ring)

	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.18, 0.19, 0.21)
	wall_mat.roughness = 0.85
	var segments := 20
	for i in segments:
		var wall := CSGBox3D.new()
		wall.size = Vector3(3.4, 2.2, 0.45)
		var ang := float(i) / float(segments) * TAU
		var r := CombatConsts.ARENA_RADIUS + 0.15
		wall.position = Vector3(sin(ang) * r, 1.1, cos(ang) * r)
		wall.rotation.y = ang
		wall.use_collision = true
		wall.collision_layer = CombatConsts.LAYER_WORLD
		wall.collision_mask = 0
		wall.material = wall_mat
		add_child(wall)

	_spawn_mark("PlayerSpawn", PLAYER_SPAWN, CombatConsts.COLOR_PLAYER)
	_spawn_mark("EnemySpawn", ENEMY_SPAWN, CombatConsts.COLOR_ENEMY_ACCENT)


func _spawn_mark(p_name: String, pos: Vector3, color: Color) -> void:
	var m := Marker3D.new()
	m.name = p_name
	m.position = pos
	add_child(m)
	var disc := CSGCylinder3D.new()
	disc.radius = 0.45
	disc.height = 0.04
	disc.sides = 16
	disc.position = Vector3(pos.x, 0.02, pos.z)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.35
	disc.material = mat
	add_child(disc)
