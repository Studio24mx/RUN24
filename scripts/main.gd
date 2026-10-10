extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/boss.tscn")
const PICKUP_SCENE := preload("res://scenes/world/pickup.tscn")
const HAZARD_SCENE := preload("res://scenes/world/hazard.tscn")
const XOLO_SCENE := preload("res://scenes/world/xolo.tscn")
const MOVING_PLATFORM_SCRIPT := preload("res://scripts/world/moving_platform.gd")
const SIGNAL_ARCH_TEXTURE := preload("res://art/exports/environment/signal_arch.svg")
const RELAY_SHRINE_TEXTURE := preload("res://art/exports/environment/relay_shrine.svg")
const CATHEDRAL_WINDOW_TEXTURE := preload("res://art/exports/environment/cathedral_window.svg")
const FLOOD_PUMP_TEXTURE := preload("res://art/exports/environment/flood_pump.svg")
const MARKET_TOTEM_TEXTURE := preload("res://art/exports/environment/market_totem.svg")
const ASCENSION_SPIRE_TEXTURE := preload("res://art/exports/environment/ascension_spire.svg")
const VISUAL_DIRECTOR_SCRIPT := preload("res://scripts/system/visual_director.gd")

const LEVEL_END_X := 16000.0
const BOSS_TRIGGER_X := 14620.0
const BOSS_GATE_X := 14350.0

var player
var xolo
var boss
var room_counts := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0, 8: 0, 9: 0}
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
var health_pips := []
var core_pips := []
var zone_title_label: Label
var current_zone_index := -1
var controls_hint_left := 0.0
var minimap_origin := Vector2(760, 20)
var minimap_width := 150.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_background()
	_build_world()
	var visual_director := Node.new()
	visual_director.set_script(VISUAL_DIRECTOR_SCRIPT)
	add_child(visual_director)
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
	_update_room_presentation(x)
	_update_controls_hint(delta)

	if not boss_started and x > BOSS_TRIGGER_X:
		boss_started = true
		_create_gate(99, BOSS_GATE_X, Color(0.85, 0.12, 0.29, 0.94))
		if is_instance_valid(boss):
			boss.activate()
		boss_bar.visible = true
		boss_label.visible = true
		Sfx.play("boss", -3.0)
		Sfx.start_boss_music()
		_toast("THE IDOL // FIRST NODE OF THE DEAD-NET")


func _update_room_presentation(x: float) -> void:
	var edges := [1600.0, 3200.0, 4800.0, 6400.0, 8000.0, 9600.0, 11200.0, 12800.0, BOSS_GATE_X]
	var names := ["ENTRY", "CIRCUIT", "CATHEDRAL", "FLOODWAY", "TRANSIT", "HOLLOW MARKET", "CARGADOR", "BLACK SIGNAL", "ASCENSION", "THE IDOL"]
	var zone := 9
	for i in range(edges.size()):
		if x < edges[i]:
			zone = i
			break
	room_label.text = "%02d/10 · %s" % [zone + 1, names[zone]]
	if zone != current_zone_index:
		_show_zone_title(zone)

func _show_zone_title(zone: int) -> void:
	current_zone_index = zone
	if not is_instance_valid(zone_title_label):
		return
	var names := ["ENTRY", "CIRCUIT", "CATHEDRAL", "FLOODWAY", "TRANSIT", "HOLLOW MARKET", "CARGADOR", "BLACK SIGNAL", "ASCENSION", "THE IDOL"]
	zone_title_label.text = "%02d  //  %s" % [zone + 1, names[zone]]
	zone_title_label.modulate = Color(1, 1, 1, 0)
	zone_title_label.scale = Vector2(0.92, 0.92)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(zone_title_label, "modulate:a", 1.0, 0.16)
	tween.tween_property(zone_title_label, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_interval(0.75)
	tween.chain().tween_property(zone_title_label, "modulate:a", 0.0, 0.50)

func _update_controls_hint(delta: float) -> void:
	if not is_instance_valid(help_label):
		return
	if controls_hint_left <= 0.0:
		help_label.modulate.a = move_toward(help_label.modulate.a, 0.0, delta * 1.6)
		return
	controls_hint_left = maxf(controls_hint_left - delta, 0.0)
	help_label.modulate.a = 0.78

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
	controls_hint_left = 9.0
	_show_zone_title(0)
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
	elif tutorial_stage == 1 and x > 1650.0:
		tutorial_stage = 2
		_toast("CORE CHARGES ON HIT // Q OR Y = SPECIAL")
	elif tutorial_stage == 2 and x > 3300.0:
		tutorial_stage = 3
		_toast("DOWN THROUGH PLATFORMS // S OR ↓")
	elif tutorial_stage == 3 and x > 6500.0:
		tutorial_stage = 4
		_toast("MOVING RELAYS // READ THE RHYTHM, THEN COMMIT")
	elif tutorial_stage == 4 and x > 9650.0:
		tutorial_stage = 5
		_toast("ELITE SIGNAL // CARGADOR CHARGES IN A STRAIGHT LINE")
	elif tutorial_stage == 5 and x > 12850.0:
		tutorial_stage = 6
		_toast("ASCENSION // SPEND CORE. THE IDOL IS AHEAD.")

func _update_checkpoints(x: float) -> void:
	if checkpoint_stage == 0 and x > 3200.0:
		checkpoint_stage = 1
		player.set_checkpoint(Vector2(3270, 600))
		_toast("CHECKPOINT // SIGNAL ANCHORED")
	elif checkpoint_stage == 1 and x > 6400.0:
		checkpoint_stage = 2
		player.set_checkpoint(Vector2(6480, 600))
		_toast("CHECKPOINT // TRANSIT LOCKED")
	elif checkpoint_stage == 2 and x > 9600.0:
		checkpoint_stage = 3
		player.set_checkpoint(Vector2(9680, 600))
		_toast("CHECKPOINT // ELITE NODE")
	elif checkpoint_stage == 3 and x > 12800.0:
		checkpoint_stage = 4
		player.set_checkpoint(Vector2(12880, 600))
		_toast("CHECKPOINT // FINAL UPLINK")

func _build_background() -> void:
	# Signalpunk value blocks: obsidian dominates; jade/cochineal are functional accents.
	var colors := [
		Color(0.018, 0.024, 0.038, 0.93),
		Color(0.028, 0.022, 0.045, 0.92),
		Color(0.018, 0.040, 0.046, 0.92),
		Color(0.045, 0.018, 0.035, 0.92)
	]
	for i in range(13):
		_add_back_rect(Vector2(650.0 + i * 1300.0, 360.0), Vector2(1300, 720), colors[i % colors.size()])

	# Monumental signal suns anchor the composition without competing with combat.
	_add_back_circle(Vector2(920, 235), 190.0, Color(0.85, 0.12, 0.29, 0.12), -9)
	_add_back_circle(Vector2(3660, 220), 240.0, Color(0.85, 0.12, 0.29, 0.10), -9)
	_add_back_circle(Vector2(6460, 205), 275.0, Color(0.85, 0.12, 0.29, 0.14), -9)
	_add_back_circle(Vector2(9720, 230), 210.0, Color(0.85, 0.12, 0.29, 0.10), -9)
	_add_back_circle(Vector2(12750, 205), 315.0, Color(0.85, 0.12, 0.29, 0.13), -9)
	_add_back_circle(Vector2(15150, 185), 360.0, Color(0.85, 0.12, 0.29, 0.18), -9)

	# Layered brutalist skyline built from reusable silhouettes.
	for x in range(90, 15980, 170):
		var height := 90.0 + float((x * 7) % 190)
		var width := 92.0 + float((x * 3) % 70)
		_add_back_rect(Vector2(float(x), 620.0 - height * 0.5), Vector2(width, height), Color(0.035, 0.050, 0.065, 0.92))
		if int(x / 170) % 3 == 0:
			_add_back_rect(Vector2(float(x), 582.0 - height), Vector2(5, 72), Color(0.20, 0.84, 0.78, 0.16))

	for tower_x in [560.0, 1980.0, 3480.0, 4700.0, 5840.0, 7150.0, 8420.0, 10120.0, 11640.0, 13250.0, 14900.0]:
		_add_signal_tower(Vector2(tower_x, 430.0))

	for marker_x in [1180.0, 2860.0, 4260.0, 5480.0, 6640.0, 7480.0, 8920.0, 10480.0, 12150.0, 13720.0, 15360.0]:
		_add_signal_marker(Vector2(marker_x, 300.0), 54.0)

	for fall_x in [1510.0, 3650.0, 5220.0, 7180.0, 8760.0, 10980.0, 12620.0, 14160.0, 15620.0]:
		_add_signal_fall(Vector2(fall_x, 170.0), 390.0)
	for banner_x in [310.0, 1740.0, 3370.0, 4910.0, 6040.0, 7590.0, 8320.0, 9880.0, 11420.0, 13120.0, 14840.0]:
		_add_signal_banner(Vector2(banner_x, 270.0))
	_add_cable(Vector2(70, 155), Vector2(760, 210), 72.0)
	_add_cable(Vector2(4550, 145), Vector2(5650, 205), 95.0)
	_add_cable(Vector2(6600, 130), Vector2(7900, 190), 90.0)
	_add_cable(Vector2(8220, 140), Vector2(9450, 205), 86.0)
	_add_cable(Vector2(11100, 150), Vector2(12380, 215), 94.0)
	_add_cable(Vector2(13600, 120), Vector2(15800, 195), 120.0)

	for arch_x in [1450.0, 4720.0, 8160.0, 11380.0, 14580.0]:
		_add_background_prop(SIGNAL_ARCH_TEXTURE, Vector2(arch_x, 505), Vector2(0.72, 0.72), Color(1, 1, 1, 0.62), -5)
	for shrine_x in [680.0, 2580.0, 7350.0, 10480.0, 12150.0, 15420.0]:
		_add_background_prop(RELAY_SHRINE_TEXTURE, Vector2(shrine_x, 535), Vector2(0.56, 0.56), Color(1, 1, 1, 0.56), -4)

	# District-specific authored landmarks give every act its own silhouette.
	for cathedral_x in [3500.0, 4270.0]:
		_add_background_prop(CATHEDRAL_WINDOW_TEXTURE, Vector2(cathedral_x, 470), Vector2(0.66, 0.66), Color(1, 1, 1, 0.72), -5)
	for pump_x in [5250.0, 6060.0]:
		_add_background_prop(FLOOD_PUMP_TEXTURE, Vector2(pump_x, 540), Vector2(0.62, 0.62), Color(0.88, 1.0, 1.0, 0.68), -4)
	for market_x in [8380.0, 9200.0]:
		_add_background_prop(MARKET_TOTEM_TEXTURE, Vector2(market_x, 505), Vector2(0.64, 0.64), Color(1.0, 0.88, 0.90, 0.74), -4)
	_add_background_prop(MARKET_TOTEM_TEXTURE, Vector2(11820, 500), Vector2(0.72, 0.72), Color(0.62, 0.38, 0.48, 0.64), -4)
	for spire_x in [13280.0, 14020.0]:
		_add_background_prop(ASCENSION_SPIRE_TEXTURE, Vector2(spire_x, 445), Vector2(0.70, 0.70), Color(0.92, 0.95, 1.0, 0.76), -5)

func _add_background_prop(texture: Texture2D, pos: Vector2, prop_scale: Vector2, tint: Color, layer: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = pos
	sprite.scale = prop_scale
	sprite.modulate = tint
	sprite.z_index = layer
	add_child(sprite)

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

	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(glow, "modulate:a", 0.35, 0.55)
	pulse.tween_property(glow, "modulate:a", 1.0, 0.75)
	var core_pulse := create_tween()
	core_pulse.set_loops()
	core_pulse.tween_property(core, "modulate:a", 0.45, 0.40)
	core_pulse.tween_property(core, "modulate:a", 1.0, 0.65)

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

	var sway := create_tween()
	sway.set_loops()
	var direction := -1.0 if int(pos.x / 100.0) % 2 == 0 else 1.0
	sway.tween_property(cloth, "rotation", direction * 0.035, 1.4)
	sway.parallel().tween_property(glyph, "rotation", direction * 0.030, 1.4)
	sway.tween_property(cloth, "rotation", -direction * 0.028, 1.6)
	sway.parallel().tween_property(glyph, "rotation", -direction * 0.024, 1.6)

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
	var spin := create_tween()
	spin.set_loops()
	spin.tween_property(ring, "rotation", TAU, 14.0).from(0.0)

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
	var floor_color := Color(0.042, 0.052, 0.072)
	var platform_color := Color(0.070, 0.100, 0.130)

	# Act I — Entry / Circuit / Cathedral.
	_make_platform(Vector2(800, 680), Vector2(1600, 80), floor_color)
	_make_platform(Vector2(2000, 680), Vector2(700, 80), floor_color)
	_make_platform(Vector2(2800, 680), Vector2(800, 80), floor_color)
	_make_platform(Vector2(3600, 680), Vector2(800, 80), floor_color)
	_make_platform(Vector2(4450, 680), Vector2(700, 80), floor_color)

	_make_platform(Vector2(470, 520), Vector2(260, 24), platform_color, true)
	_make_platform(Vector2(870, 420), Vector2(230, 24), platform_color, true)
	_make_platform(Vector2(1260, 505), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(1780, 485), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(2080, 365), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(2520, 490), Vector2(240, 24), platform_color, true)
	_make_platform(Vector2(2920, 365), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(3380, 500), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(3700, 390), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(4180, 495), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(4520, 350), Vector2(180, 24), platform_color, true)

	# Act II — Floodway / Transit / Hollow Market.
	_make_platform(Vector2(5200, 680), Vector2(700, 80), floor_color)
	_make_platform(Vector2(6000, 680), Vector2(650, 80), floor_color)
	_make_platform(Vector2(6900, 680), Vector2(760, 80), floor_color)
	_make_platform(Vector2(7750, 680), Vector2(700, 80), floor_color)
	_make_platform(Vector2(8600, 680), Vector2(760, 80), floor_color)
	_make_platform(Vector2(9450, 680), Vector2(650, 80), floor_color)

	_make_platform(Vector2(5000, 500), Vector2(190, 24), platform_color, true)
	_make_moving_platform(Vector2(5360, 475), Vector2(170, 22), Vector2(0, -150), 2.7, 0.0)
	_make_platform(Vector2(5700, 350), Vector2(180, 24), platform_color, true)
	_make_moving_platform(Vector2(6100, 450), Vector2(180, 22), Vector2(0, -180), 3.1, 1.4)
	_make_platform(Vector2(6550, 510), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(6900, 385), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(7350, 500), Vector2(240, 24), platform_color, true)
	_make_platform(Vector2(7760, 365), Vector2(180, 24), platform_color, true)
	_make_platform(Vector2(8150, 505), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(8460, 390), Vector2(230, 24), platform_color, true)
	_make_platform(Vector2(8900, 500), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(9260, 370), Vector2(190, 24), platform_color, true)

	# Act III — Cargador / Black Signal / Ascension.
	_make_platform(Vector2(10300, 680), Vector2(1250, 80), floor_color)
	_make_platform(Vector2(11600, 680), Vector2(1050, 80), floor_color)
	_make_platform(Vector2(12720, 680), Vector2(950, 80), floor_color)
	_make_platform(Vector2(13800, 680), Vector2(1000, 80), floor_color)
	_make_platform(Vector2(15175, 680), Vector2(1650, 80), floor_color)

	_make_platform(Vector2(9850, 500), Vector2(190, 24), platform_color, true)
	_make_platform(Vector2(10220, 390), Vector2(230, 24), platform_color, true)
	_make_platform(Vector2(10700, 510), Vector2(220, 24), platform_color, true)
	_make_platform(Vector2(11020, 365), Vector2(180, 24), platform_color, true)
	_make_moving_platform(Vector2(11480, 490), Vector2(180, 22), Vector2(0, -170), 2.8, 0.7)
	_make_platform(Vector2(11840, 365), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(12240, 500), Vector2(230, 24), platform_color, true)
	_make_moving_platform(Vector2(12620, 470), Vector2(170, 22), Vector2(0, -210), 3.0, 2.1)
	_make_platform(Vector2(13020, 500), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(13350, 385), Vector2(200, 24), platform_color, true)
	_make_moving_platform(Vector2(13720, 470), Vector2(180, 22), Vector2(0, -220), 2.5, 0.3)
	_make_platform(Vector2(14060, 345), Vector2(190, 24), platform_color, true)

	# Boss arena — wide, readable and intentionally less cluttered.
	_make_platform(Vector2(14720, 500), Vector2(210, 24), platform_color, true)
	_make_platform(Vector2(15150, 390), Vector2(230, 24), platform_color, true)
	_make_platform(Vector2(15600, 505), Vector2(200, 24), platform_color, true)

	_make_platform(Vector2(-20, 360), Vector2(40, 720), floor_color)
	_make_platform(Vector2(16020, 360), Vector2(40, 720), floor_color)

	# Hazards define rhythm without turning the floor into constant punishment.
	for hazard_data in [
		[1120.0, 1.0], [2440.0, 0.9], [3950.0, 0.8],
		[5580.0, 0.95], [6260.0, 0.8], [7480.0, 0.9],
		[8840.0, 1.0], [10550.0, 1.15], [11930.0, 0.9],
		[13120.0, 0.85], [13950.0, 0.75]
	]:
		_spawn_hazard(Vector2(hazard_data[0], 628), hazard_data[1])

	for beacon_x in [3270.0, 6480.0, 9680.0, 12880.0]:
		_add_checkpoint_beacon(Vector2(beacon_x, 570))

	# Nine combat locks, then the boss lock is created dynamically.
	var gate_colors := [
		Color(0.20, 0.84, 0.78, 0.90), Color(0.95, 0.61, 0.08, 0.90),
		Color(0.85, 0.12, 0.29, 0.92), Color(0.20, 0.84, 0.78, 0.90),
		Color(0.95, 0.61, 0.08, 0.90), Color(0.85, 0.12, 0.29, 0.92),
		Color(0.95, 0.61, 0.08, 0.92), Color(0.20, 0.84, 0.78, 0.92),
		Color(0.85, 0.12, 0.29, 0.94)
	]
	var gate_x := [1600.0, 3200.0, 4800.0, 6400.0, 8000.0, 9600.0, 11200.0, 12800.0, BOSS_GATE_X]
	for i in range(9):
		_create_gate(i + 1, gate_x[i], gate_colors[i])

func _add_checkpoint_beacon(pos: Vector2) -> void:
	var root := Node2D.new()
	root.position = pos
	root.z_index = 2
	add_child(root)

	var stem := Line2D.new()
	stem.points = PackedVector2Array([Vector2(0, 40), Vector2(0, -42)])
	stem.width = 7.0
	stem.default_color = Color(0.05, 0.08, 0.10, 0.95)
	root.add_child(stem)

	var ring := Line2D.new()
	var points := PackedVector2Array()
	for i in range(25):
		points.append(Vector2.RIGHT.rotated(TAU * float(i) / 24.0) * 25.0 + Vector2(0, -45))
	ring.points = points
	ring.width = 3.0
	ring.default_color = Color(0.20, 0.84, 0.78, 0.90)
	root.add_child(ring)

	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(0, -57), Vector2(12, -45), Vector2(0, -33), Vector2(-12, -45)])
	core.color = Color(0.95, 0.61, 0.08, 0.92)
	root.add_child(core)

	var pulse := create_tween()
	pulse.set_loops()
	pulse.tween_property(core, "scale", Vector2(1.20, 1.20), 0.65)
	pulse.parallel().tween_property(ring, "modulate:a", 0.42, 0.65)
	pulse.tween_property(core, "scale", Vector2.ONE, 0.65)
	pulse.parallel().tween_property(ring, "modulate:a", 1.0, 0.65)

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

	var top_cap := Polygon2D.new()
	top_cap.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5 - 7, -size.y * 0.5 + 8),
		Vector2(-size.x * 0.5 + 7, -size.y * 0.5 + 8)
	])
	top_cap.color = Color(0.12, 0.19, 0.22, 0.95)
	body.add_child(top_cap)

	var edge := Line2D.new()
	edge.points = PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5)])
	edge.width = 3.0
	edge.default_color = Color(0.20, 0.84, 0.78, 0.88)
	body.add_child(edge)

	var lower_edge := Line2D.new()
	lower_edge.points = PackedVector2Array([
		Vector2(-size.x * 0.46, size.y * 0.5 - 5),
		Vector2(size.x * 0.46, size.y * 0.5 - 5)
	])
	lower_edge.width = 2.0
	lower_edge.default_color = Color(0.85, 0.12, 0.29, 0.42)
	body.add_child(lower_edge)

	if one_way:
		var bracket := Polygon2D.new()
		bracket.polygon = PackedVector2Array([
			Vector2(-22, size.y * 0.5), Vector2(22, size.y * 0.5),
			Vector2(13, size.y * 0.5 + 19), Vector2(0, size.y * 0.5 + 27),
			Vector2(-13, size.y * 0.5 + 19)
		])
		bracket.color = Color(0.025, 0.04, 0.055, 0.94)
		bracket.z_index = -1
		body.add_child(bracket)
		var bracket_rune := Line2D.new()
		bracket_rune.points = PackedVector2Array([
			Vector2(-8, size.y * 0.5 + 9), Vector2(0, size.y * 0.5 + 17),
			Vector2(8, size.y * 0.5 + 9)
		])
		bracket_rune.width = 2.0
		bracket_rune.default_color = Color(0.95, 0.61, 0.08, 0.62)
		body.add_child(bracket_rune)
	else:
		var foundation := Polygon2D.new()
		foundation.polygon = PackedVector2Array([
			Vector2(-size.x * 0.5, size.y * 0.10),
			Vector2(size.x * 0.5, size.y * 0.10),
			Vector2(size.x * 0.5, size.y * 0.5),
			Vector2(-size.x * 0.5, size.y * 0.5)
		])
		foundation.color = Color(0.025, 0.032, 0.045, 0.72)
		body.add_child(foundation)

	# Authored-looking modular surface language: ribs, seams and signal inlays.
	if size.x >= 150.0:
		var seam_count := maxi(int(size.x / 110.0), 1)
		for i in range(1, seam_count + 1):
			var local_x := -size.x * 0.5 + float(i) * size.x / float(seam_count + 1)
			var seam := Line2D.new()
			seam.points = PackedVector2Array([
				Vector2(local_x, -size.y * 0.28),
				Vector2(local_x, size.y * 0.32)
			])
			seam.width = 2.0
			seam.default_color = Color(0.02, 0.03, 0.045, 0.70)
			body.add_child(seam)
			if i % 2 == 0:
				var rune := Line2D.new()
				rune.points = PackedVector2Array([
					Vector2(local_x - 10, 2), Vector2(local_x, -8),
					Vector2(local_x + 10, 2), Vector2(local_x, 12)
				])
				rune.width = 2.0
				rune.default_color = Color(0.85, 0.12, 0.29, 0.38)
				body.add_child(rune)

	add_child(body)
	return body

func _make_moving_platform(pos: Vector2, size: Vector2, travel: Vector2, period: float, phase: float) -> AnimatableBody2D:
	var body := AnimatableBody2D.new()
	body.set_script(MOVING_PLATFORM_SCRIPT)
	body.position = pos
	body.collision_layer = 1
	body.collision_mask = 0
	body.sync_to_physics = true

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)

	var visual := Polygon2D.new()
	visual.polygon = PackedVector2Array([
		Vector2(-size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, -size.y * 0.5),
		Vector2(size.x * 0.5, size.y * 0.5),
		Vector2(-size.x * 0.5, size.y * 0.5)
	])
	visual.color = Color(0.055, 0.080, 0.105)
	body.add_child(visual)

	var top := Line2D.new()
	top.points = PackedVector2Array([Vector2(-size.x * 0.5, -size.y * 0.5), Vector2(size.x * 0.5, -size.y * 0.5)])
	top.width = 4.0
	top.default_color = Color(0.95, 0.61, 0.08, 0.88)
	body.add_child(top)

	var core := Line2D.new()
	core.points = PackedVector2Array([Vector2(-size.x * 0.28, 2), Vector2(size.x * 0.28, 2)])
	core.width = 3.0
	core.default_color = Color(0.20, 0.84, 0.78, 0.62)
	body.add_child(core)

	add_child(body)
	body.setup(travel, period, phase)
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
	# 01 ENTRY — simple silhouettes and basic aim.
	_spawn_enemy("walker", Vector2(620, 570), 1)
	_spawn_enemy("turret", Vector2(900, 375), 1)
	_spawn_enemy("walker", Vector2(1310, 570), 1)

	# 02 CIRCUIT — first sustained ranged encounter.
	_spawn_enemy("walker", Vector2(1760, 570), 2)
	_spawn_enemy("flyer", Vector2(2050, 165), 2)
	_spawn_enemy("turret", Vector2(2520, 445), 2)
	_spawn_enemy("walker", Vector2(2970, 570), 2)

	# 03 CATHEDRAL — vertical target prioritization.
	_spawn_enemy("walker", Vector2(3380, 570), 3)
	_spawn_enemy("turret", Vector2(3700, 345), 3)
	_spawn_enemy("flyer", Vector2(4120, 175), 3)
	_spawn_enemy("walker", Vector2(4470, 570), 3)
	_spawn_enemy("flyer", Vector2(4650, 145), 3)

	# 04 FLOODWAY — moving relays under crossfire.
	_spawn_enemy("walker", Vector2(5000, 570), 4)
	_spawn_enemy("flyer", Vector2(5350, 160), 4)
	_spawn_enemy("turret", Vector2(5700, 305), 4)
	_spawn_enemy("walker", Vector2(6140, 570), 4)
	_spawn_enemy("flyer", Vector2(6280, 165), 4)

	# 05 TRANSIT — alternating height and pressure.
	_spawn_enemy("walker", Vector2(6630, 570), 5)
	_spawn_enemy("flyer", Vector2(7000, 175), 5)
	_spawn_enemy("turret", Vector2(7350, 455), 5)
	_spawn_enemy("walker", Vector2(7790, 570), 5)

	# 06 HOLLOW MARKET — denser mixed encounter.
	_spawn_enemy("walker", Vector2(8180, 570), 6)
	_spawn_enemy("turret", Vector2(8460, 345), 6)
	_spawn_enemy("flyer", Vector2(8860, 165), 6)
	_spawn_enemy("walker", Vector2(9280, 570), 6)
	_spawn_enemy("flyer", Vector2(9460, 190), 6)

	# 07 CARGADOR — first true elite arena.
	_spawn_enemy("walker", Vector2(9860, 570), 7)
	_spawn_enemy("charger", Vector2(10300, 570), 7)
	_spawn_enemy("turret", Vector2(10700, 465), 7)
	_spawn_enemy("flyer", Vector2(11040, 165), 7)

	# 08 BLACK SIGNAL — elite plus moving relay.
	_spawn_enemy("walker", Vector2(11480, 570), 8)
	_spawn_enemy("flyer", Vector2(11840, 155), 8)
	_spawn_enemy("turret", Vector2(12240, 455), 8)
	_spawn_enemy("flyer", Vector2(12580, 170), 8)
	_spawn_enemy("charger", Vector2(12680, 570), 8)

	# 09 ASCENSION — final gauntlet before the boss.
	_spawn_enemy("walker", Vector2(13020, 570), 9)
	_spawn_enemy("turret", Vector2(13350, 340), 9)
	_spawn_enemy("flyer", Vector2(13720, 150), 9)
	_spawn_enemy("charger", Vector2(14010, 570), 9)
	_spawn_enemy("flyer", Vector2(14210, 180), 9)

	# Build progression: each recovery comes after a meaningful difficulty step.
	_spawn_pickup("spread", Vector2(1660, 585))
	_spawn_pickup("heal", Vector2(3090, 585))
	_spawn_pickup("rapid", Vector2(4880, 585))
	_spawn_pickup("core", Vector2(6480, 585))
	_spawn_pickup("heal", Vector2(8050, 585))
	_spawn_pickup("core", Vector2(9660, 585))
	_spawn_pickup("heal", Vector2(11320, 585))
	_spawn_pickup("core", Vector2(12900, 585))
	_spawn_pickup("heal", Vector2(14470, 585))

	boss = BOSS_SCENE.instantiate()
	add_child(boss)
	boss.arena_center_x = 15220.0
	boss.global_position = Vector2(15220, 300)
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
	for room_id in [1, 2, 3, 4, 5, 6, 7, 8, 9]:
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
	top_panel.size = Vector2(1280, 56)
	top_panel.color = Color(0.015, 0.020, 0.032, 0.76)
	hud.add_child(top_panel)

	var top_accent := ColorRect.new()
	top_accent.position = Vector2(0, 53)
	top_accent.size = Vector2(1280, 2)
	top_accent.color = Color(0.20, 0.84, 0.78, 0.52)
	hud.add_child(top_accent)

	var bottom_accent := ColorRect.new()
	bottom_accent.position = Vector2(0, 716)
	bottom_accent.size = Vector2(1280, 2)
	bottom_accent.color = Color(0.85, 0.12, 0.29, 0.28)
	hud.add_child(bottom_accent)

	var signal_tag := Label.new()
	signal_tag.position = Vector2(570, 39)
	signal_tag.size = Vector2(160, 20)
	signal_tag.text = "RUN24 // SIGNALPUNK"
	signal_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	signal_tag.add_theme_font_size_override("font_size", 11)
	signal_tag.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82, 0.56))
	hud.add_child(signal_tag)

	# Compact ten-zone minimap used for orientation during external playtests.
	var map_bg := ColorRect.new()
	map_bg.position = minimap_origin - Vector2(5, 3)
	map_bg.size = Vector2(minimap_width + 10, 22)
	map_bg.color = Color(0.025, 0.032, 0.050, 0.88)
	hud.add_child(map_bg)
	for i in range(10):
		var cell := ColorRect.new()
		cell.position = minimap_origin + Vector2(float(i) * (minimap_width / 10.0), 2)
		cell.size = Vector2(minimap_width / 10.0 - 2.0, 10)
		cell.color = Color(0.12, 0.16, 0.19, 0.95) if i < 9 else Color(0.20, 0.05, 0.10, 0.95)
		hud.add_child(cell)
	minimap_dot = ColorRect.new()
	minimap_dot.position = minimap_origin + Vector2(0, 0)
	minimap_dot.size = Vector2(5, 14)
	minimap_dot.color = Color(0.95, 0.61, 0.08, 1.0)
	hud.add_child(minimap_dot)

	health_label = Label.new()
	health_label.position = Vector2(24, 16)
	health_label.text = "LIFE"
	health_label.add_theme_font_size_override("font_size", 22)
	health_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	hud.add_child(health_label)

	for i in range(5):
		var heart := Polygon2D.new()
		heart.polygon = PackedVector2Array([
			Vector2(0, 8), Vector2(-10, 0), Vector2(-10, -8),
			Vector2(-5, -13), Vector2(0, -8), Vector2(5, -13),
			Vector2(10, -8), Vector2(10, 0)
		])
		heart.position = Vector2(95 + i * 25, 29)
		heart.color = Color(0.85, 0.12, 0.29)
		hud.add_child(heart)
		health_pips.append(heart)

	weapon_label = Label.new()
	weapon_label.position = Vector2(210, 18)
	weapon_label.add_theme_font_size_override("font_size", 21)
	weapon_label.add_theme_color_override("font_color", Color(0.20, 0.84, 0.78))
	hud.add_child(weapon_label)

	core_label = Label.new()
	core_label.position = Vector2(500, 18)
	core_label.text = "CORE"
	core_label.add_theme_font_size_override("font_size", 20)
	core_label.add_theme_color_override("font_color", Color(0.95, 0.61, 0.08))
	hud.add_child(core_label)

	for i in range(3):
		var core_icon := Polygon2D.new()
		core_icon.polygon = PackedVector2Array([
			Vector2(0, -10), Vector2(9, -5), Vector2(9, 5),
			Vector2(0, 10), Vector2(-9, 5), Vector2(-9, -5)
		])
		core_icon.position = Vector2(585 + i * 27, 29)
		core_icon.color = Color(0.18, 0.15, 0.10)
		hud.add_child(core_icon)
		core_pips.append(core_icon)

	room_label = Label.new()
	room_label.position = Vector2(930, 18)
	room_label.size = Vector2(320, 36)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	room_label.add_theme_font_size_override("font_size", 19)
	room_label.add_theme_color_override("font_color", Color(0.85, 0.12, 0.29))
	hud.add_child(room_label)

	help_label = Label.new()
	help_label.position = Vector2(24, 684)
	help_label.size = Vector2(1220, 26)
	help_label.add_theme_font_size_override("font_size", 11)
	help_label.add_theme_color_override("font_color", Color(0.80, 0.84, 0.86, 0.78))
	hud.add_child(help_label)

	zone_title_label = Label.new()
	zone_title_label.position = Vector2(300, 154)
	zone_title_label.size = Vector2(680, 64)
	zone_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zone_title_label.add_theme_font_size_override("font_size", 38)
	zone_title_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.82))
	zone_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
	zone_title_label.add_theme_constant_override("shadow_offset_x", 3)
	zone_title_label.add_theme_constant_override("shadow_offset_y", 3)
	zone_title_label.modulate.a = 0.0
	hud.add_child(zone_title_label)

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
	start_label.text = "RUN24\nSIGNALPUNK\n\nTHE SIGNAL OF THE DEAD HAS BEEN HIJACKED.\nYOU ARE RUNNER 24. CROSS TEN NODES AND REACH THE ORIGIN.\n\nFINAL PROTOTYPE · TARGET RUN 12–20 MIN\n\nPRESS ANY KEY / CLICK / GAMEPAD BUTTON TO CONNECT"
	start_overlay.add_child(start_label)

func _update_controls(gamepad: bool) -> void:
	if not is_instance_valid(help_label):
		return
	if gamepad:
		help_label.text = "L-STICK MOVE  ·  A JUMP  ·  B/RB DASH  ·  R-STICK AIM  ·  RT FIRE  ·  Y SPECIAL  ·  START PAUSE"
	else:
		help_label.text = "A/D MOVE  ·  SPACE JUMP  ·  SHIFT DASH  ·  MOUSE AIM/FIRE  ·  Q SPECIAL  ·  E NOVA  ·  ESC PAUSE"

func _update_minimap() -> void:
	if not is_instance_valid(minimap_dot) or not is_instance_valid(player):
		return
	var ratio := clampf(player.global_position.x / LEVEL_END_X, 0.0, 1.0)
	minimap_dot.position = minimap_origin + Vector2(ratio * (minimap_width - 5.0), 0)

func _update_health(current: int, maximum: int) -> void:
	if is_instance_valid(health_label):
		health_label.text = "LIFE"
	for i in range(health_pips.size()):
		var heart = health_pips[i]
		if is_instance_valid(heart):
			heart.color = Color(0.85, 0.12, 0.29) if i < current else Color(0.16, 0.17, 0.20)

func _update_core(current: float, maximum: float) -> void:
	if not is_instance_valid(core_label):
		return
	core_label.text = "CORE  %.1f" % current
	var full := clampi(int(floor(current + 0.001)), 0, int(maximum))
	for i in range(core_pips.size()):
		var icon = core_pips[i]
		if is_instance_valid(icon):
			icon.color = Color(0.95, 0.61, 0.08) if i < full else Color(0.18, 0.15, 0.10)

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
	Sfx.stop_music()
	Sfx.play("victory", -3.0)
	_show_end(true)

func _on_player_died() -> void:
	if level_finished:
		return
	level_finished = true
	Sfx.stop_music()
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
		"build": "signalpunk_final_prototype_1"
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
