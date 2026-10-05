extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/boss.tscn")
const PICKUP_SCENE := preload("res://scenes/world/pickup.tscn")
const HAZARD_SCENE := preload("res://scenes/world/hazard.tscn")

var player
var boss
var room_counts := {1: 0, 2: 0, 3: 0}
var gates := {}
var gate_reconcile_left := 0.0
var boss_started := false
var level_finished := false

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

func _ready() -> void:
	_build_background()
	_build_world()
	_spawn_player()
	_build_hud()
	_update_controls(player.using_gamepad)
	_spawn_level_content()
	_update_health(player.health, player.max_health)
	_update_core(player.core_energy, player.core_max)
	_update_weapon("WEAPON: BASIC")
	_toast("ZONE 01 // SIGNAL DISTRICT")

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		return

	if not level_finished and player.global_position.y > 860.0:
		player.fall_respawn()
		_toast("VOID HIT // -1 HP")

	gate_reconcile_left -= delta
	if gate_reconcile_left <= 0.0:
		gate_reconcile_left = 0.25
		_reconcile_room_gates()

	if not boss_started and player.global_position.x > 4180.0:
		boss_started = true
		_create_gate(99, 4050.0, Color(1.0, 0.18, 0.52, 0.9))
		if is_instance_valid(boss):
			boss.activate()
		boss_bar.visible = true
		boss_label.visible = true
		_toast("BOSS // NEON IDOL")

	var x: float = float(player.global_position.x)
	if x < 1450.0:
		room_label.text = "ROOM 1/4  ·  ENTRY"
	elif x < 3100.0:
		room_label.text = "ROOM 2/4  ·  CIRCUIT"
	elif x < 4050.0:
		room_label.text = "ROOM 3/4  ·  PRESSURE"
	else:
		room_label.text = "ROOM 4/4  ·  NEON IDOL"

func _unhandled_input(event: InputEvent) -> void:
	if not level_finished:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
	elif event is InputEventJoypadButton and event.pressed and event.button_index in [JOY_BUTTON_A, JOY_BUTTON_START]:
		get_tree().reload_current_scene()

func _build_background() -> void:
	var colors := [
		Color(0.025, 0.03, 0.07),
		Color(0.045, 0.025, 0.08),
		Color(0.025, 0.055, 0.075),
		Color(0.07, 0.025, 0.065)
	]
	for i in range(4):
		_add_back_rect(Vector2(650.0 + i * 1300.0, 360.0), Vector2(1300, 720), colors[i])
	for x in range(160, 5150, 260):
		var light := Polygon2D.new()
		light.polygon = PackedVector2Array([Vector2(-3, -42), Vector2(3, -42), Vector2(3, 42), Vector2(-3, 42)])
		light.color = Color(0.1, 0.75, 0.9, 0.15) if int(x / 260) % 2 == 0 else Color(1.0, 0.2, 0.6, 0.12)
		light.position = Vector2(x, 250 + (x % 3) * 35)
		light.z_index = -8
		add_child(light)

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

func _build_world() -> void:
	var floor_color := Color(0.12, 0.15, 0.24)
	var platform_color := Color(0.20, 0.25, 0.38)

	_make_platform(Vector2(725, 680), Vector2(1450, 80), floor_color)
	_make_platform(Vector2(1725, 680), Vector2(550, 80), floor_color)
	_make_platform(Vector2(2650, 680), Vector2(900, 80), floor_color)
	_make_platform(Vector2(3350, 680), Vector2(500, 80), floor_color)
	_make_platform(Vector2(3925, 680), Vector2(250, 80), floor_color)
	_make_platform(Vector2(4625, 680), Vector2(1150, 80), floor_color)

	_make_platform(Vector2(470, 520), Vector2(260, 24), platform_color, true)
	_make_platform(Vector2(870, 420), Vector2(230, 24), platform_color, true)
	_make_platform(Vector2(1190, 520), Vector2(190, 24), platform_color, true)

	_make_platform(Vector2(1650, 520), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(1900, 405), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(2390, 500), Vector2(250, 24), platform_color, true)
	_make_platform(Vector2(2780, 410), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(2980, 525), Vector2(150, 24), platform_color, true)

	_make_platform(Vector2(3260, 505), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(3480, 385), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(3900, 495), Vector2(180, 24), platform_color, true)

	_make_platform(Vector2(4310, 500), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(4830, 470), Vector2(200, 24), platform_color, true)

	_make_platform(Vector2(-20, 360), Vector2(40, 720), floor_color)
	_make_platform(Vector2(5220, 360), Vector2(40, 720), floor_color)

	_spawn_hazard(Vector2(1110, 628), 1.0)
	_spawn_hazard(Vector2(2570, 628), 1.25)
	_spawn_hazard(Vector2(3390, 628), 0.9)
	_spawn_hazard(Vector2(3895, 628), 0.7)

	_create_gate(1, 1450.0, Color(0.2, 0.9, 1.0, 0.85))
	_create_gate(2, 3100.0, Color(1.0, 0.72, 0.18, 0.85))
	_create_gate(3, 4050.0, Color(1.0, 0.24, 0.68, 0.85))

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
	edge.default_color = Color(0.2, 0.85, 0.95, 0.55)
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
	_toast("ARENA CLEAR // GATE OPEN")

func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = Vector2(180, 580)
	player.set_checkpoint(player.global_position)
	player.health_changed.connect(_update_health)
	player.weapon_changed.connect(_update_weapon)
	player.core_changed.connect(_update_core)
	player.special_used.connect(_toast)
	player.input_scheme_changed.connect(_update_controls)
	player.died.connect(_on_player_died)

func _spawn_level_content() -> void:
	_spawn_enemy("walker", Vector2(640, 570), 1)
	_spawn_enemy("turret", Vector2(900, 375), 1)
	_spawn_enemy("walker", Vector2(1270, 570), 1)

	_spawn_enemy("walker", Vector2(1690, 570), 2)
	_spawn_enemy("flyer", Vector2(1980, 150), 2)
	_spawn_enemy("turret", Vector2(2400, 455), 2)
	_spawn_enemy("flyer", Vector2(2820, 160), 2)

	_spawn_enemy("walker", Vector2(3260, 570), 3)
	_spawn_enemy("turret", Vector2(3480, 340), 3)
	_spawn_enemy("flyer", Vector2(3910, 200), 3)

	_spawn_pickup("spread", Vector2(1570, 585))
	_spawn_pickup("heal", Vector2(2290, 585))
	_spawn_pickup("rapid", Vector2(3185, 585))

	boss = BOSS_SCENE.instantiate()
	add_child(boss)
	boss.global_position = Vector2(4580, 300)
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
	if is_instance_valid(player):
		player.add_core(0.18)
	room_counts[room_id] = maxi(room_counts[room_id] - 1, 0)
	_reconcile_room_gate(room_id)

func _reconcile_room_gates() -> void:
	for room_id in [1, 2, 3]:
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

	health_label = Label.new()
	health_label.position = Vector2(24, 16)
	health_label.add_theme_font_size_override("font_size", 25)
	hud.add_child(health_label)

	weapon_label = Label.new()
	weapon_label.position = Vector2(210, 18)
	weapon_label.add_theme_font_size_override("font_size", 21)
	weapon_label.add_theme_color_override("font_color", Color(0.25, 0.95, 1.0))
	hud.add_child(weapon_label)

	core_label = Label.new()
	core_label.position = Vector2(505, 18)
	core_label.add_theme_font_size_override("font_size", 20)
	core_label.add_theme_color_override("font_color", Color(1.0, 0.78, 0.18))
	hud.add_child(core_label)

	room_label = Label.new()
	room_label.position = Vector2(930, 18)
	room_label.size = Vector2(320, 36)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	room_label.add_theme_font_size_override("font_size", 19)
	room_label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.68))
	hud.add_child(room_label)

	help_label = Label.new()
	help_label.position = Vector2(22, 654)
	help_label.size = Vector2(1180, 60)
	help_label.add_theme_font_size_override("font_size", 13)
	help_label.add_theme_color_override("font_color", Color(0.72, 0.78, 0.9, 0.9))
	hud.add_child(help_label)

	toast_label = Label.new()
	toast_label.position = Vector2(340, 90)
	toast_label.size = Vector2(600, 48)
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_font_size_override("font_size", 25)
	toast_label.add_theme_color_override("font_color", Color(1.0, 0.82, 0.3))
	hud.add_child(toast_label)

	boss_label = Label.new()
	boss_label.position = Vector2(390, 88)
	boss_label.size = Vector2(500, 32)
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_label.text = "NEON IDOL"
	boss_label.add_theme_font_size_override("font_size", 18)
	boss_label.visible = false
	hud.add_child(boss_label)

	boss_bar = ProgressBar.new()
	boss_bar.position = Vector2(390, 120)
	boss_bar.size = Vector2(500, 18)
	boss_bar.min_value = 0
	boss_bar.max_value = 80
	boss_bar.value = 80
	boss_bar.show_percentage = false
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
	end_label.add_theme_font_size_override("font_size", 34)
	end_overlay.add_child(end_label)

func _update_controls(gamepad: bool) -> void:
	if not is_instance_valid(help_label):
		return
	if gamepad:
		help_label.text = "L-STICK/DPAD MOVER · A/CROSS SALTAR · B/CIRCLE/RB DASH · R-STICK APUNTAR · RT/R2 DISPARAR\nY/TRIANGLE ESPECIAL · ↓ BAJAR PLATAFORMA · ↓+Y GROUND BURST · DASH+Y PHASE RUSH"
	else:
		help_label.text = "A/D MOVER · ESPACIO SALTAR · SHIFT DASH · MOUSE DISPARAR/APUNTAR\nQ ESPECIAL · S/↓ BAJAR PLATAFORMA · S+Q GROUND BURST · DASH+Q PHASE RUSH"

func _update_health(current: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "HP  %d / %d" % [current, maximum]

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

func _on_boss_health(current: int, maximum: int) -> void:
	boss_bar.max_value = maximum
	boss_bar.value = current

func _on_boss_died() -> void:
	if level_finished:
		return
	level_finished = true
	boss_bar.visible = false
	boss_label.visible = false
	_show_end(true)

func _on_player_died() -> void:
	if level_finished:
		return
	level_finished = true
	_show_end(false)

func _show_end(victory: bool) -> void:
	end_overlay.visible = true
	if victory:
		end_label.text = "SIGNAL RESTORED\n\nPROTOTYPE CLEAR\n\nR / A-CROSS / START  ·  PLAY AGAIN"
		end_label.add_theme_color_override("font_color", Color(0.25, 1.0, 0.72))
	else:
		end_label.text = "SIGNAL LOST\n\nRUN FAILED\n\nR / A-CROSS / START  ·  RETRY"
		end_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.5))
