extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/boss.tscn")
const PICKUP_SCENE := preload("res://scenes/world/pickup.tscn")
const HAZARD_SCENE := preload("res://scenes/world/hazard.tscn")
const XOLO_SCENE := preload("res://scenes/world/xolo.tscn")

const LEVEL_END_X := 8000.0
const BOSS_TRIGGER_X := 6920.0
const BOSS_GATE_X := 6800.0

var player
var xolo
var boss
var room_counts := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0}
var gates := {}
var gate_reconcile_left := 0.0
var boss_started := false
var level_finished := false
var run_started := false
var tutorial_stage := 0
var checkpoint_stage := 0

var run_seconds := 0.0
var stat_shots := 0
var stat_hits := 0
var stat_damage := 0
var stat_kills := 0
var stat_specials := 0
var stat_pickups := 0

var health_label: Label
var weapon_label: Label
var core_label: Label
var room_label: Label
var toast_label: Label
var boss_label: Label
var boss_bar: ProgressBar
var end_overlay: ColorRect
var end_label: Label
var help_label: Label
var start_overlay: ColorRect
var start_label: Label
var minimap_dot: ColorRect
var minimap_origin := Vector2(760, 20)
var minimap_width := 150.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_background()
	_build_world()
	_spawn_player()
	_spawn_xolo()
	_build_hud()
	_update_controls(player.using_gamepad)
	_spawn_level_content()
	_update_health(player.health, player.max_health)
	_update_core(player.core_energy, player.core_max)
	_update_weapon("WEAPON: BASIC")
	_update_minimap()
	get_tree().paused = true

func _process(delta: float) -> void:
	if not is_instance_valid(player) or not run_started or level_finished:
		return

	run_seconds += delta

	if player.global_position.y > 860.0:
		player.fall_respawn()
		_toast("VOID HIT // -1 LIFE")

	gate_reconcile_left -= delta
	if gate_reconcile_left <= 0.0:
		gate_reconcile_left = 0.25
		_reconcile_room_gates()

	var x: float = float(player.global_position.x)
	_update_tutorial(x)
	_update_checkpoints(x)
	_update_minimap()

	if not boss_started and x > BOSS_TRIGGER_X:
		boss_started = true
		_create_gate(99, BOSS_GATE_X, Color(0.85, 0.12, 0.29, 0.94))
		if is_instance_valid(boss):
			boss.activate()
		boss_bar.visible = true
		boss_label.visible = true
		Sfx.play("boss", -3.0)
		_toast("THE IDOL // FIRST NODE OF THE DEAD-NET")

	if x < 1450.0:
		room_label.text = "01/06 · ENTRY"
	elif x < 3100.0:
		room_label.text = "02/06 · CIRCUIT"
	elif x < 4550.0:
		room_label.text = "03/06 · PRESSURE"
	elif x < 5750.0:
		room_label.text = "04/06 · TRANSIT"
	elif x < BOSS_GATE_X:
		room_label.text = "05/06 · CARGADOR"
	else:
		room_label.text = "06/06 · THE IDOL"

func _unhandled_input(event: InputEvent) -> void:
	var pressed := false
	if event is InputEventKey:
		pressed = event.pressed and not event.echo
	elif event is InputEventMouseButton:
		pressed = event.pressed
	elif event is InputEventJoypadButton:
		pressed = event.pressed

	if not run_started:
		if pressed:
			_start_run()
		return

	if level_finished:
		if event is InputEventKey and event.pressed and event.keycode == KEY_R:
			get_tree().paused = false
			get_tree().reload_current_scene()
		elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
			get_tree().paused = false
			get_tree().reload_current_scene()
		return

	if (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE) or (event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START):
		_toggle_pause()

func _start_run() -> void:
	run_started = true
	start_overlay.visible = false
	get_tree().paused = false
	_toast("MOVE // A-D OR L-STICK  ·  JUMP // SPACE OR A")

func _toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	start_overlay.visible = paused
	if paused:
		start_label.text = "SIGNAL PAUSED\n\nESC / START  ·  RESUME"
	else:
		start_overlay.visible = false

func _update_tutorial(x: float) -> void:
	if tutorial_stage == 0 and x > 430.0:
		tutorial_stage = 1
		_toast("AIM + FIRE // MOUSE  ·  R-STICK + RT")
	elif tutorial_stage == 1 and x > 1530.0:
		tutorial_stage = 2
		_toast("CORE CHARGES ON HIT // Q OR Y = SPECIAL")
	elif tutorial_stage == 2 and x > 3150.0:
		tutorial_stage = 3
		_toast("DOWN THROUGH PLATFORMS // S OR ↓")
	elif tutorial_stage == 3 and x > 5820.0:
		tutorial_stage = 4
		_toast("ELITE SIGNAL // CARGADOR CHARGES IN A STRAIGHT LINE")

func _update_checkpoints(x: float) -> void:
	if checkpoint_stage == 0 and x > 3140.0:
		checkpoint_stage = 1
		player.set_checkpoint(Vector2(3220, 600))
		_toast("CHECKPOINT // SIGNAL ANCHORED")
	elif checkpoint_stage == 1 and x > 5810.0:
		checkpoint_stage = 2
		player.set_checkpoint(Vector2(5880, 600))
		_toast("CHECKPOINT // FINAL UPLINK")

func _build_background() -> void:
	# Signalpunk value blocks: obsidian dominates; jade/cochineal are functional accents.
	var colors := [
		Color(0.018, 0.024, 0.038),
		Color(0.028, 0.022, 0.045),
		Color(0.018, 0.040, 0.046),
		Color(0.045, 0.018, 0.035)
	]
	for i in range(6):
		_add_back_rect(Vector2(650.0 + i * 1300.0, 360.0), Vector2(1300, 720), colors[i % colors.size()])

	# Monumental signal suns anchor the composition without competing with combat.
	_add_back_circle(Vector2(920, 235), 190.0, Color(0.85, 0.12, 0.29, 0.12), -9)
	_add_back_circle(Vector2(3660, 220), 240.0, Color(0.85, 0.12, 0.29, 0.10), -9)
	_add_back_circle(Vector2(6460, 205), 275.0, Color(0.85, 0.12, 0.29, 0.14), -9)

	# Layered brutalist skyline built from reusable silhouettes.
	for x in range(90, 7980, 170):
		var height := 90.0 + float((x * 7) % 190)
		var width := 92.0 + float((x * 3) % 70)
		_add_back_rect(Vector2(float(x), 620.0 - height * 0.5), Vector2(width, height), Color(0.035, 0.050, 0.065, 0.92))
		if int(x / 170) % 3 == 0:
			_add_back_rect(Vector2(float(x), 582.0 - height), Vector2(5, 72), Color(0.20, 0.84, 0.78, 0.16))

	for tower_x in [560.0, 1980.0, 3480.0, 4700.0, 5840.0, 7150.0]:
		_add_signal_tower(Vector2(tower_x, 430.0))

	for marker_x in [1180.0, 2860.0, 4260.0, 5480.0, 6640.0, 7480.0]:
		_add_signal_marker(Vector2(marker_x, 300.0), 54.0)

	for fall_x in [1510.0, 3650.0, 5220.0, 7180.0]:
		_add_signal_fall(Vector2(fall_x, 170.0), 390.0)
	for banner_x in [310.0, 1740.0, 3370.0, 4910.0, 6040.0, 7590.0]:
		_add_signal_banner(Vector2(banner_x, 270.0))
	_add_cable(Vector2(70, 155), Vector2(760, 210), 72.0)
	_add_cable(Vector2(4550, 145), Vector2(5650, 205), 95.0)
	_add_cable(Vector2(6600, 130), Vector2(7900, 190), 90.0)

func _add_signal_fall(pos: Vector2, height: float) -> void:
	var glow := Polygon2D.new()
	glow.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(18, 0), Vector2(28, height), Vector2(-28, height)
	])
	glow.position = pos
	glow.color = Color(0.20, 0.84, 0.78, 0.055)
	glow.z_index = -7
	add_child(glow)
	var core := Line2D.new()
	core.points = PackedVector2Array([Vector2.ZERO, Vector2(0, height)])
	core.position = pos
	core.width = 5.0
	core.default_color = Color(0.20, 0.84, 0.78, 0.26)
	core.z_index = -6
	add_child(core)

func _add_signal_banner(pos: Vector2) -> void:
	var cloth := Polygon2D.new()
	cloth.polygon = PackedVector2Array([Vector2(-18, -45), Vector2(18, -45), Vector2(15, 45), Vector2(-14, 39)])
	cloth.position = pos
	cloth.color = Color(0.32, 0.035, 0.09, 0.72)
	cloth.z_index = -5
	add_child(cloth)
	var glyph := Line2D.new()
	glyph.points = PackedVector2Array([Vector2(0, -25), Vector2(0, 24), Vector2(-9, 11), Vector2(9, 11), Vector2(0, 24)])
	glyph.position = pos
	glyph.width = 2.5
	glyph.default_color = Color(0.85, 0.12, 0.29, 0.82)
	glyph.z_index = -4
	add_child(glyph)

func _add_cable(start: Vector2, finish: Vector2, sag: float) -> void:
	var cable := Line2D.new()
	var points := PackedVector2Array()
	for i in range(9):
		var t := float(i) / 8.0
		var point := start.lerp(finish, t)
		point.y += sin(PI * t) * sag
		points.append(point)
	cable.points = points
	cable.width = 4.0
	cable.default_color = Color(0.015, 0.020, 0.030, 0.94)
	cable.z_index = -5
	add_child(cable)

func _add_back_rect(pos: Vector2, size: Vector2, color: Color) -> void:
	var poly := Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	poly.position = pos
	poly.color = color
	poly.z_index = -10
	add_child(poly)

func _add_back_circle(pos: Vector2, radius: float, color: Color, layer: int) -> void:
	var poly := Polygon2D.new()
	var points := PackedVector2Array()
	for i in range(40):
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / 40.0) * radius)
	poly.polygon = points
	poly.position = pos
	poly.color = color
	poly.z_index = layer
	add_child(poly)

func _add_signal_tower(pos: Vector2) -> void:
	var tower := Polygon2D.new()
	tower.polygon = PackedVector2Array([
		Vector2(-42, 170), Vector2(-34, -110), Vector2(-13, -154),
		Vector2(13, -154), Vector2(34, -110), Vector2(42, 170)
	])
	tower.position = pos
	tower.color = Color(0.025, 0.034, 0.050, 0.96)
	tower.z_index = -7
	add_child(tower)

	var spine := Line2D.new()
	spine.points = PackedVector2Array([Vector2(0, 145), Vector2(0, -135)])
	spine.width = 4.0
	spine.default_color = Color(0.20, 0.84, 0.78, 0.20)
	spine.position = pos
	spine.z_index = -6
	add_child(spine)

	for y in [-92.0, -35.0, 22.0, 79.0]:
		var bar := Line2D.new()
		bar.points = PackedVector2Array([Vector2(-26, y), Vector2(26, y)])
		bar.width = 3.0
		bar.default_color = Color(0.85, 0.12, 0.29, 0.18)
		bar.position = pos
		bar.z_index = -6
		add_child(bar)

func _add_signal_marker(pos: Vector2, radius: float) -> void:
	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in range(33):
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / 32.0) * radius)
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(0.85, 0.12, 0.29, 0.18)
	ring.position = pos
	ring.z_index = -6
	add_child(ring)

	var cross := Line2D.new()
	cross.points = PackedVector2Array([
		Vector2(-radius * 0.7, 0), Vector2(radius * 0.7, 0),
		Vector2.ZERO, Vector2(0, -radius * 0.7),
		Vector2(0, radius * 0.7)
	])
	cross.width = 2.0
	cross.default_color = Color(0.95, 0.88, 0.78, 0.13)
	cross.position = pos
	cross.z_index = -6
	add_child(cross)

func _build_world() -> void:
	var floor_color := Color(0.055, 0.065, 0.090)
	var platform_color := Color(0.080, 0.110, 0.140)

	# Six encounter zones with deliberate breathing spaces and readable gaps.
	_make_platform(Vector2(725, 680), Vector2(1450, 80), floor_color)
	_make_platform(Vector2(1750, 680), Vector2(600, 80), floor_color)
	_make_platform(Vector2(2650, 680), Vector2(900, 80), floor_color)
	_make_platform(Vector2(3350, 680), Vector2(500, 80), floor_color)
	_make_platform(Vector2(4175, 680), Vector2(750, 80), floor_color)
	_make_platform(Vector2(4875, 680), Vector2(650, 80), floor_color)
	_make_platform(Vector2(5550, 680), Vector2(400, 80), floor_color)
	_make_platform(Vector2(6075, 680), Vector2(650, 80), floor_color)
	_make_platform(Vector2(6650, 680), Vector2(300, 80), floor_color)
	_make_platform(Vector2(7400, 680), Vector2(1200, 80), floor_color)

	# Entry / movement language.
	_make_platform(Vector2(470, 520), Vector2(260, 24), platform_color, true)
	_make_platform(Vector2(870, 420), Vector2(230, 24), platform_color, true)
	_make_platform(Vector2(1190, 520), Vector2(190, 24), platform_color, true)

	# Circuit / ranged combat.
	_make_platform(Vector2(1650, 520), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(1900, 405), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(2390, 500), Vector2(250, 24), platform_color, true)
	_make_platform(Vector2(2780, 410), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(2980, 525), Vector2(150, 24), platform_color, true)

	# Pressure / vertical target prioritization.
	_make_platform(Vector2(3260, 505), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(3480, 385), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(3900, 495), Vector2(180, 24), platform_color, true)
	_make_platform(Vector2(4310, 390), Vector2(210, 24), platform_color, true)

	# Transit / mixed traversal.
	_make_platform(Vector2(4720, 505), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(5010, 390), Vector2(180, 24), platform_color, true)
	_make_platform(Vector2(5420, 470), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(5620, 350), Vector2(150, 24), platform_color, true)

	# Cargador arena.
	_make_platform(Vector2(5960, 485), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(6240, 385), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(6540, 490), Vector2(170, 24), platform_color, true)

	# THE IDOL arena supports aerial specials without hiding the boss.
	_make_platform(Vector2(7060, 500), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(7420, 405), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(7740, 510), Vector2(170, 24), platform_color, true)

	_make_platform(Vector2(-20, 360), Vector2(40, 720), floor_color)
	_make_platform(Vector2(8020, 360), Vector2(40, 720), floor_color)

	_spawn_hazard(Vector2(1110, 628), 1.0)
	_spawn_hazard(Vector2(2570, 628), 1.25)
	_spawn_hazard(Vector2(3390, 628), 0.9)
	_spawn_hazard(Vector2(4140, 628), 0.9)
	_spawn_hazard(Vector2(4870, 628), 0.85)
	_spawn_hazard(Vector2(5550, 628), 0.75)
	_spawn_hazard(Vector2(6110, 628), 0.9)

	_create_gate(1, 1450.0, Color(0.20, 0.84, 0.78, 0.88))
	_create_gate(2, 3100.0, Color(0.95, 0.61, 0.08, 0.88))
	_create_gate(3, 4550.0, Color(0.85, 0.12, 0.29, 0.90))
	_create_gate(4, 5750.0, Color(0.20, 0.84, 0.78, 0.90))
	_create_gate(5, BOSS_GATE_X, Color(0.95, 0.61, 0.08, 0.92))

func _make_platform(pos: Vector2, size: Vector2, color: Color, one_way: bool = false) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.position = pos
	body.collision_layer = 32 if one_way else 1
	body.collision_mask = 0
	if one_way:
		body.add_to_group("drop_through_platforms")

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	collision.one_way_collision = one_way
	collision.one_way_collision_margin = 14.0
	body.add_child(collision)

	# One-way platforms stay passable for the player, but bullets need a solid
	# geometry blocker from every direction. Layer 7 (mask value 64) is reserved
	# exclusively for projectile blockers.
	if one_way:
		var projectile_blocker := StaticBody2D.new()
		projectile_blocker.position = pos
		projectile_blocker.collision_layer = 64
		projectile_blocker.collision_mask = 0
		var blocker_shape := RectangleShape2D.new()
		blocker_shape.size = size
		var blocker_collision := CollisionShape2D.new()
		blocker_collision.shape = blocker_shape
		projectile_blocker.add_child(blocker_collision)
		add_child(projectile_blocker)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	visual.color = color
	body.add_child(visual)

	var edge := Line2D.new()
	edge.points = PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5)])
	edge.width = 3.0
	edge.default_color = Color(0.20, 0.84, 0.78, 0.68)
	body.add_child(edge)

	add_child(body)
	return body

func _create_gate(room_id: int, x: float, color: Color) -> void:
	if gates.has(room_id) and is_instance_valid(gates[room_id]):
		return
	var gate := _make_platform(Vector2(x, 330), Vector2(28, 620), color)
	gate.name = "Gate_%s" % room_id
	gates[room_id] = gate

func _open_gate(room_id: int) -> void:
	if not gates.has(room_id):
		return
	var gate = gates[room_id]
	if not is_instance_valid(gate):
		gates.erase(room_id)
		return
	gates.erase(room_id)
	gate.collision_layer = 0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(gate, "scale:y", 0.02, 0.32)
	tween.tween_property(gate, "modulate:a", 0.0, 0.32)
	tween.chain().tween_callback(gate.queue_free)
	Sfx.play("gate", -7.0)
	_toast("ARENA CLEAR // GATE OPEN")

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = Vector2(180, 580)
	player.set_checkpoint(player.global_position)
	player.health_changed.connect(_update_health)
	player.weapon_changed.connect(_update_weapon)
	player.core_changed.connect(_update_core)
	player.special_used.connect(_on_special_used)
	player.input_scheme_changed.connect(_update_controls)
	player.shot_fired.connect(_on_shot_fired)
	player.hit_confirmed.connect(_on_hit_confirmed)
	player.damage_taken.connect(_on_damage_taken)
	player.pickup_collected.connect(_on_pickup_collected)
	player.died.connect(_on_player_died)

func _spawn_xolo() -> void:
	xolo = XOLO_SCENE.instantiate()
	add_child(xolo)
	xolo.player = player
	xolo.global_position = player.global_position + Vector2(-72, -18)

func _spawn_level_content() -> void:
	# 01 ENTRY — teaches movement and simple target order.
	_spawn_enemy("walker", Vector2(640, 570), 1)
	_spawn_enemy("turret", Vector2(900, 375), 1)
	_spawn_enemy("walker", Vector2(1270, 570), 1)

	# 02 CIRCUIT — first sustained ranged encounter.
	_spawn_enemy("walker", Vector2(1690, 570), 2)
	_spawn_enemy("flyer", Vector2(1980, 150), 2)
	_spawn_enemy("turret", Vector2(2400, 455), 2)
	_spawn_enemy("flyer", Vector2(2820, 160), 2)

	# 03 PRESSURE — mixed elevations and hazards.
	_spawn_enemy("walker", Vector2(3260, 570), 3)
	_spawn_enemy("turret", Vector2(3480, 340), 3)
	_spawn_enemy("flyer", Vector2(3910, 200), 3)
	_spawn_enemy("walker", Vector2(4350, 570), 3)

	# 04 TRANSIT — traversal under crossfire.
	_spawn_enemy("walker", Vector2(4720, 570), 4)
	_spawn_enemy("flyer", Vector2(5050, 175), 4)
	_spawn_enemy("turret", Vector2(5420, 425), 4)
	_spawn_enemy("walker", Vector2(5620, 570), 4)

	# 05 CARGADOR — elite skill check before the boss.
	_spawn_enemy("walker", Vector2(5920, 570), 5)
	_spawn_enemy("charger", Vector2(6250, 570), 5)
	_spawn_enemy("flyer", Vector2(6550, 180), 5)

	# Upgrades are spaced to let testers experience distinct build states.
	_spawn_pickup("spread", Vector2(1570, 585))
	_spawn_pickup("heal", Vector2(2290, 585))
	_spawn_pickup("rapid", Vector2(3185, 585))
	_spawn_pickup("core", Vector2(4680, 585))
	_spawn_pickup("heal", Vector2(5840, 585))
	_spawn_pickup("core", Vector2(6700, 585))

	boss = BOSS_SCENE.instantiate()
	add_child(boss)
	boss.arena_center_x = 7420.0
	boss.global_position = Vector2(7420, 300)
	boss.health_changed.connect(_on_boss_health)
	boss.died.connect(_on_boss_died)

func _spawn_enemy(kind: String, pos: Vector2, room_id: int) -> void:
	var enemy = ENEMY_SCENE.instantiate()
	enemy.enemy_type = kind
	enemy.room_id = room_id
	enemy.position = pos
	add_child(enemy)
	enemy.add_to_group("room_%d_enemies" % room_id)
	enemy.died.connect(_on_enemy_died)
	room_counts[room_id] += 1

func _spawn_pickup(kind: String, pos: Vector2) -> void:
	var pickup = PICKUP_SCENE.instantiate()
	pickup.kind = kind
	pickup.position = pos
	add_child(pickup)

func _spawn_hazard(pos: Vector2, scale_x: float) -> void:
	var hazard = HAZARD_SCENE.instantiate()
	add_child(hazard)
	hazard.global_position = pos
	hazard.scale.x = scale_x

func _on_enemy_died(_enemy, room_id: int) -> void:
	stat_kills += 1
	Sfx.play("kill", -10.0)
	if is_instance_valid(player):
		player.add_core(0.18)
	room_counts[room_id] = maxi(room_counts[room_id] - 1, 0)
	_reconcile_room_gate(room_id)

func _reconcile_room_gates() -> void:
	for room_id in [1, 2, 3, 4, 5]:
		_reconcile_room_gate(room_id)

func _reconcile_room_gate(room_id: int) -> void:
	if not gates.has(room_id):
		return
	var live_count := 0
	for enemy in get_tree().get_nodes_in_group("room_%d_enemies" % room_id):
		if is_instance_valid(enemy) and not enemy.dead:
			live_count += 1
	room_counts[room_id] = live_count
	if live_count == 0:
		_open_gate(room_id)

func _build_hud() -> void:
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)

	var top_panel := ColorRect.new()
	top_panel.position = Vector2.ZERO
	top_panel.size = Vector2(1280, 62)
	top_panel.color = Color(0.015, 0.020, 0.032, 0.90)
	hud.add_child(top_panel)

	var top_accent := ColorRect.new()
	top_accent.position = Vector2(0, 58)
	top_accent.size = Vector2(1280, 3)
	top_accent.color = Color(0.20, 0.84, 0.78, 0.52)
	hud.add_child(top_accent)

	var bottom_panel := ColorRect.new()
	bottom_panel.position = Vector2(0, 646)
	bottom_panel.size = Vector2(1280, 74)
	bottom_panel.color = Color(0.015, 0.020, 0.032, 0.86)
	hud.add_child(bottom_panel)

	var bottom_accent := ColorRect.new()
	bottom_accent.position = Vector2(0, 646)
	bottom_accent.size = Vector2(1280, 2)
	bottom_accent.color = Color(0.85, 0.12, 0.29, 0.45)
	hud.add_child(bottom_accent)

	var signal_tag := Label.new()
	signal_tag.position = Vector2(570, 39)
	signal_tag.size = Vector2(160, 20)
	signal_tag.text = "RUN24 // SIGNALPUNK"
	signal_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	signal_tag.add_theme_font_size_override("font_size", 11)
	signal_tag.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82, 0.56))
	hud.add_child(signal_tag)

	# Compact six-zone minimap used for orientation during external playtests.
	var map_bg := ColorRect.new()
	map_bg.position = minimap_origin - Vector2(5, 3)
	map_bg.size = Vector2(minimap_width + 10, 22)
	map_bg.color = Color(0.025, 0.032, 0.050, 0.88)
	hud.add_child(map_bg)
	for i in range(6):
		var cell := ColorRect.new()
		cell.position = minimap_origin + Vector2(float(i) * (minimap_width / 6.0), 2)
		cell.size = Vector2(minimap_width / 6.0 - 3.0, 10)
		cell.color = Color(0.12, 0.16, 0.19, 0.95) if i < 5 else Color(0.20, 0.05, 0.10, 0.95)
		hud.add_child(cell)
	minimap_dot = ColorRect.new()
	minimap_dot.position = minimap_origin + Vector2(0, 0)
	minimap_dot.size = Vector2(5, 14)
	minimap_dot.color = Color(0.95, 0.61, 0.08, 1.0)
	hud.add_child(minimap_dot)

	health_label = Label.new()
	health_label.position = Vector2(24, 16)
	health_label.add_theme_font_size_override("font_size", 25)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	hud.add_child(health_label)

	weapon_label = Label.new()
	weapon_label.position = Vector2(210, 18)
	weapon_label.add_theme_font_size_override("font_size", 21)
	weapon_label.add_theme_color_override("font_color", Color(0.20, 0.84, 0.78))
	hud.add_child(weapon_label)

	core_label = Label.new()
	core_label.position = Vector2(505, 18)
	core_label.add_theme_font_size_override("font_size", 20)
	core_label.add_theme_color_override("font_color", Color(0.95, 0.61, 0.08))
	hud.add_child(core_label)

	room_label = Label.new()
	room_label.position = Vector2(930, 18)
	room_label.size = Vector2(320, 36)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	room_label.add_theme_font_size_override("font_size", 19)
	room_label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.29))
	hud.add_child(room_label)

	help_label = Label.new()
	help_label.position = Vector2(22, 654)
	help_label.size = Vector2(1180, 60)
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color(0.78, 0.82, 0.84, 0.92))
	hud.add_child(help_label)

	toast_label = Label.new()
	toast_label.position = Vector2(340, 90)
	toast_label.size = Vector2(600, 48)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 25)
	toast_label.add_theme_color_override("font_color", Color(0.95, 0.61, 0.08))
	hud.add_child(toast_label)

	boss_label = Label.new()
	boss_label.position = Vector2(390, 88)
	boss_label.size = Vector2(500, 32)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.text = "THE IDOL"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.29))
	boss_label.visible = false
	hud.add_child(boss_label)

	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(390, 120)
	boss_bar.size = Vector2(500, 18)
	boss_bar.min_value = 0
	boss_bar.max_value = 80
	boss_bar.value = 80
	boss_bar.show_percentage = false
	var boss_bg := StyleBoxFlat.new()
	boss_bg.bg_color = Color(0.025, 0.032, 0.050, 0.94)
	boss_bg.border_width_left = 2
	boss_bg.border_width_top = 2
	boss_bg.border_width_right = 2
	boss_bg.border_width_bottom = 2
	boss_bg.border_color = Color(0.95, 0.90, 0.82, 0.45)
	var boss_fill := StyleBoxFlat.new()
	boss_fill.bg_color = Color(0.85, 0.12, 0.29, 0.92)
	boss_bar.add_theme_stylebox_override("background", boss_bg)
	boss_bar.add_theme_stylebox_override("fill", boss_fill)
	boss_bar.visible = false
	hud.add_child(boss_bar)

	end_overlay = ColorRect.new()
	end_overlay.position = Vector2.ZERO
	end_overlay.size = Vector2(1280, 720)
	end_overlay.color = Color(0.015, 0.018, 0.04, 0.88)
	end_overlay.visible = false
	hud.add_child(end_overlay)

	end_label = Label.new()
	end_label.position = Vector2(240, 250)
	end_label.size = Vector2(800, 220)
	end_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	end_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	end_label.add_theme_font_size_override("font_size", 30)
	end_overlay.add_child(end_label)

	start_overlay = ColorRect.new()
	start_overlay.position = Vector2.ZERO
	start_overlay.size = Vector2(1280, 720)
	start_overlay.color = Color(0.008, 0.012, 0.020, 0.95)
	hud.add_child(start_overlay)

	start_label = Label.new()
	start_label.position = Vector2(170, 150)
	start_label.size = Vector2(940, 420)
	start_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	start_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	start_label.add_theme_font_size_override("font_size", 24)
	start_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	start_label.text = "RUN24\nSIGNALPUNK\n\nTHE SIGNAL OF THE DEAD HAS BEEN HIJACKED.\nYOU ARE RUNNER 24. CROSS THE SIX NODES AND REACH THE ORIGIN.\n\nFIELD TEST BUILD · 6–12 MIN\n\nPRESS ANY KEY / CLICK / GAMEPAD BUTTON TO CONNECT"
	start_overlay.add_child(start_label)

func _update_controls(gamepad: bool) -> void:
	if not is_instance_valid(help_label):
		return
	if gamepad:
		help_label.text = "L-STICK/DPAD MOVER · A/CROSS SALTAR · B/CIRCLE/RB DASH · R-STICK APUNTAR · RT/R2 DISPARAR · ↓ BAJAR\nY ESPECIAL · ↑+Y SKY · ↓+Y GROUND · DASH+Y PHASE · LB NOVA PULSE"
	else:
		help_label.text = "A/D MOVER · ESPACIO SALTAR · SHIFT DASH · MOUSE DISPARAR/APUNTAR · S/↓ BAJAR\nQ ESPECIAL · W+Q SKY · S+Q GROUND · DASH+Q PHASE · E NOVA PULSE"

func _update_minimap() -> void:
	if not is_instance_valid(minimap_dot) or not is_instance_valid(player):
		return
	var ratio := clampf(player.global_position.x / LEVEL_END_X, 0.0, 1.0)
	minimap_dot.position = minimap_origin + Vector2(ratio * (minimap_width - 5.0), 0)

func _update_health(current: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		var alive := "♥".repeat(maxi(current, 0))
		var lost := "♡".repeat(maxi(maximum - current, 0))
		health_label.text = "LIFE " + alive + lost

func _update_core(current: float, maximum: float) -> void:
	if not is_instance_valid(core_label):
		return
	var full := clampi(int(floor(current + 0.001)), 0, int(maximum))
	var empty := maxi(int(maximum) - full, 0)
	core_label.text = "CORE " + "◆".repeat(full) + "◇".repeat(empty) + "  %.1f" % current

func _update_weapon(text: String) -> void:
	if is_instance_valid(weapon_label):
		weapon_label.text = text
	if text != "WEAPON: BASIC":
		_toast(text)

func _toast(text: String) -> void:
	if not is_instance_valid(toast_label):
		return
	toast_label.text = text
	toast_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.15)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.55)

func _on_special_used(text: String) -> void:
	if text.begins_with("SPECIAL"):
		stat_specials += 1
	_toast(text)

func _on_shot_fired() -> void:
	stat_shots += 1

func _on_hit_confirmed() -> void:
	stat_hits += 1

func _on_damage_taken(amount: int) -> void:
	stat_damage += amount

func _on_pickup_collected(_kind: String) -> void:
	stat_pickups += 1

func _on_boss_health(current: int, maximum: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_died() -> void:
	if level_finished:
		return
	level_finished = true
	boss_bar.visible = false
	boss_label.visible = false
	Sfx.play("victory", -3.0)
	_show_end(true)

func _on_player_died() -> void:
	if level_finished:
		return
	level_finished = true
	Sfx.play("death", -3.0)
	_show_end(false)

func _format_time(seconds: float) -> String:
	var total := int(round(seconds))
	var minutes := total / 60
	var secs := total % 60
	return "%02d:%02d" % [minutes, secs]

func _save_playtest_summary(victory: bool) -> void:
	var data := {
		"victory": victory,
		"time_seconds": run_seconds,
		"shots": stat_shots,
		"hits": stat_hits,
		"damage_taken": stat_damage,
		"enemies_defeated": stat_kills,
		"specials_used": stat_specials,
		"pickups_collected": stat_pickups,
		"furthest_x": player.global_position.x if is_instance_valid(player) else 0.0,
		"build": "signalpunk_vertical_slice_1"
	}
	var file := FileAccess.open("user://last_playtest.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "\t"))

func _show_end(victory: bool) -> void:
	_save_playtest_summary(victory)
	end_overlay.visible = true
	var result := "SIGNAL RESTORED" if victory else "SIGNAL LOST"
	var subtitle := "THE IDOL DISCONNECTED" if victory else "RUNNER 24 TERMINATED"
	var metrics := "TIME  %s   ·   ENEMIES  %d   ·   HITS  %d\nDAMAGE TAKEN  %d   ·   SPECIALS  %d   ·   PICKUPS  %d" % [
		_format_time(run_seconds), stat_kills, stat_hits, stat_damage, stat_specials, stat_pickups
	]
	end_label.text = "%s\n%s\n\n%s\n\nR / A-CROSS / START  ·  RUN AGAIN" % [result, subtitle, metrics]
	end_label.add_theme_color_override("font_color", Color(0.20, 0.84, 0.78) if victory else Color(0.85, 0.12, 0.29))
	get_tree().paused = true
