extends CharacterBody2D

signal health_changed(current, maximum)
signal weapon_changed(text)
signal core_changed(current, maximum)
signal special_used(text)
signal died
signal input_scheme_changed(using_gamepad: bool)
signal shot_fired
signal hit_confirmed
signal damage_taken(amount: int)
signal pickup_collected(kind: String)

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")
const FX_BURST_SCENE := preload("res://scenes/fx/burst.tscn")

@export var move_speed := 440.0
@export var acceleration := 4600.0
@export var friction := 5200.0
@export var jump_velocity := -1025.0
@export var gravity_up := 2850.0
@export var gravity_down := 6000.0
@export var max_fall_speed := 2200.0
@export var coyote_time := 0.12
@export var jump_buffer_time := 0.12
@export var dash_speed := 760.0
@export var dash_duration := 0.14
@export var dash_cooldown := 0.25

var max_health := 5
var health := 5
var facing := 1.0
var coyote_left := 0.0
var jump_buffer_left := 0.0
var dash_left := 0.0
var dash_cooldown_left := 0.0
var invulnerability_left := 0.0
var fire_left := 0.0
var fire_interval := 0.15
var spread_level := 1
var dead := false
var checkpoint_position := Vector2.ZERO
var safe_checkpoint_left := 0.0
var safe_checkpoint_interval := 0.28
var drop_request_left := 0.0
var drop_request_window := 0.12
var drop_through_left := 0.0
var drop_through_duration := 0.20
var using_gamepad := false
var aim_direction := Vector2.RIGHT
var aim_deadzone := 0.28

# Special system: 3 CORE charges maximum; each special activation costs one.
var core_max := 3.0
var core_energy := 1.0
var special_dir_buffer := Vector2.ZERO
var special_dir_left := 0.0
var special_buffer_time := 0.14
var phase_rush_left := 0.0
var phase_rush_duration := 0.18
var phase_rush_speed := 1250.0
var phase_hit_ids := {}
var camera_shake := 0.0
var visual_time := 0.0
var recoil_anim := 0.0
var dash_trail_left := 0.0
var last_grounded := false

@onready var camera: Camera2D = $Camera2D
@onready var body_visual: Node2D = $VisualRoot
@onready var authored_sprite: Sprite2D = $VisualRoot/AuthoredSprite
@onready var core_visual: Polygon2D = $VisualRoot/CoreGlow
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var weapon_sprite: Sprite2D = $WeaponPivot/WeaponSprite

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 37
	checkpoint_position = global_position
	_setup_input_actions()
	using_gamepad = not Input.get_connected_joypads().is_empty()
	queue_redraw()

func _input(event: InputEvent) -> void:
	var previous := using_gamepad
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		using_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		using_gamepad = false
	if previous != using_gamepad:
		input_scheme_changed.emit(using_gamepad)
		queue_redraw()

func _setup_input_actions() -> void:
	_add_joy_axis("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_axis("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button("move_left", JOY_BUTTON_DPAD_LEFT)
	_add_joy_button("move_right", JOY_BUTTON_DPAD_RIGHT)
	_add_joy_button("jump", JOY_BUTTON_A)
	_add_joy_button("dash", JOY_BUTTON_B)
	_add_joy_button("dash", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_axis("shoot", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_button("shoot", JOY_BUTTON_X)

	_ensure_action("aim_left", 0.22)
	_ensure_action("aim_right", 0.22)
	_ensure_action("aim_up", 0.22)
	_ensure_action("aim_down", 0.22)
	_add_joy_axis("aim_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_joy_axis("aim_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_joy_axis("aim_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_joy_axis("aim_down", JOY_AXIS_RIGHT_Y, 1.0)

	_ensure_action("special", 0.2)
	_ensure_action("special_alt", 0.2)
	_ensure_action("special_up", 0.2)
	_ensure_action("special_down", 0.60)
	_add_key("special", KEY_Q)
	_add_joy_button("special", JOY_BUTTON_Y)
	_add_key("special_alt", KEY_E)
	_add_joy_button("special_alt", JOY_BUTTON_LEFT_SHOULDER)
	_add_key("special_up", KEY_W)
	_add_key("special_up", KEY_UP)
	_add_key("special_down", KEY_S)
	_add_key("special_down", KEY_DOWN)
	_add_joy_button("special_up", JOY_BUTTON_DPAD_UP)
	_add_joy_button("special_down", JOY_BUTTON_DPAD_DOWN)
	_add_joy_axis("special_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_axis("special_down", JOY_AXIS_LEFT_Y, 1.0)

func _ensure_action(action: StringName, deadzone: float = 0.2) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)

func _add_key(action: StringName, key: int) -> void:
	_ensure_action(action)
	var event := InputEventKey.new()
	event.physical_keycode = key
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _add_joy_button(action: StringName, button: int) -> void:
	_ensure_action(action)
	var event := InputEventJoypadButton.new()
	event.button_index = button
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _add_joy_axis(action: StringName, axis: int, value: float) -> void:
	_ensure_action(action)
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	if not InputMap.action_has_event(action, event):
		InputMap.action_add_event(action, event)

func _physics_process(delta: float) -> void:
	if dead:
		return

	visual_time += delta
	recoil_anim = maxf(recoil_anim - delta, 0.0)
	dash_trail_left = maxf(dash_trail_left - delta, 0.0)
	_update_camera_shake(delta)
	_update_aim_direction()
	_update_special_direction_buffer(delta)
	_update_drop_through(delta)
	_update_safe_checkpoint(delta)
	fire_left = maxf(fire_left - delta, 0.0)
	invulnerability_left = maxf(invulnerability_left - delta, 0.0)

	if invulnerability_left > 0.0:
		modulate.a = 0.45 if int(invulnerability_left * 20.0) % 2 == 0 else 1.0
	else:
		modulate.a = 1.0

	if Input.is_action_pressed("shoot") and fire_left <= 0.0 and phase_rush_left <= 0.0:
		_shoot()
		fire_left = fire_interval

	if is_on_floor():
		coyote_left = coyote_time
	else:
		coyote_left = maxf(coyote_left - delta, 0.0)

	if Input.is_action_just_pressed("jump"):
		jump_buffer_left = jump_buffer_time
	else:
		jump_buffer_left = maxf(jump_buffer_left - delta, 0.0)

	if Input.is_action_just_pressed("special_down") and is_on_floor() and _has_drop_platform_below():
		drop_request_left = drop_request_window

	dash_cooldown_left = maxf(dash_cooldown_left - delta, 0.0)
	if Input.is_action_just_pressed("dash") and dash_left <= 0.0 and phase_rush_left <= 0.0 and dash_cooldown_left <= 0.0:
		var input_dir := Input.get_axis("move_left", "move_right")
		if input_dir != 0.0:
			facing = signf(input_dir)
		dash_left = dash_duration
		dash_cooldown_left = dash_cooldown
		Sfx.play("dash", -10.0)
		camera_shake = maxf(camera_shake, 1.6)

	if Input.is_action_just_pressed("special"):
		_try_special()
	if Input.is_action_just_pressed("special_alt"):
		_nova_pulse()

	if phase_rush_left > 0.0:
		phase_rush_left -= delta
		velocity = Vector2(facing * phase_rush_speed, 0.0)
		_damage_phase_rush_targets()
		_update_visual()
		if dash_trail_left <= 0.0:
			_spawn_dash_ghost(true)
			dash_trail_left = 0.035
		move_and_slide()
		_post_move_feedback()
		queue_redraw()
		return

	if dash_left > 0.0:
		dash_left -= delta
		velocity = Vector2(facing * dash_speed, 0.0)
		_update_visual()
		if dash_trail_left <= 0.0:
			_spawn_dash_ghost(false)
			dash_trail_left = 0.045
		move_and_slide()
		_post_move_feedback()
		queue_redraw()
		return

	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		facing = signf(direction)
		velocity.x = move_toward(velocity.x, direction * move_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, friction * delta)

	if not is_on_floor():
		var active_gravity := gravity_up if velocity.y < 0.0 else gravity_down
		velocity.y = minf(velocity.y + active_gravity * delta, max_fall_speed)

	if jump_buffer_left > 0.0 and coyote_left > 0.0:
		velocity.y = jump_velocity
		jump_buffer_left = 0.0
		Sfx.play("jump", -11.0)
		coyote_left = 0.0

	if Input.is_action_just_released("jump") and velocity.y < -120.0:
		velocity.y *= 0.50

	_update_visual()
	move_and_slide()
	_post_move_feedback()
	queue_redraw()

func _post_move_feedback() -> void:
	var grounded_now := is_on_floor()
	if grounded_now and not last_grounded and visual_time > 0.20:
		body_visual.scale = Vector2(facing * 1.10, 0.84)
		camera_shake = maxf(camera_shake, 1.15)
		_spawn_fx(global_position + Vector2(0, 27), Color(0.95, 0.90, 0.82), 18.0, 0.13, 7)
	last_grounded = grounded_now

func _spawn_dash_ghost(is_phase: bool) -> void:
	if not is_instance_valid(authored_sprite):
		return
	var ghost := Sprite2D.new()
	ghost.texture = authored_sprite.texture
	ghost.z_index = 5
	ghost.modulate = Color(1.0, 0.34, 0.70, 0.34) if is_phase else Color(0.20, 0.84, 0.78, 0.24)
	get_tree().current_scene.add_child(ghost)
	ghost.global_position = global_position + body_visual.position
	ghost.rotation = body_visual.rotation
	ghost.scale = Vector2(authored_sprite.scale.x * body_visual.scale.x, authored_sprite.scale.y * body_visual.scale.y)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.tween_property(ghost, "scale", ghost.scale * Vector2(1.08, 0.92), 0.18)
	tween.chain().tween_callback(ghost.queue_free)

func _update_camera_shake(delta: float) -> void:
	camera_shake = move_toward(camera_shake, 0.0, 15.0 * delta)
	if camera_shake <= 0.02:
		camera.offset = camera.offset.lerp(Vector2.ZERO, 0.35)
		return
	var t := Time.get_ticks_msec() * 0.035
	camera.offset = Vector2(sin(t * 1.7), cos(t * 2.3)) * camera_shake

func _update_special_direction_buffer(delta: float) -> void:
	special_dir_left = maxf(special_dir_left - delta, 0.0)
	var current := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("special_up", "special_down")
	)
	if current.length() > 0.35:
		special_dir_buffer = current.normalized()
		special_dir_left = special_buffer_time
	elif special_dir_left <= 0.0:
		special_dir_buffer = Vector2.ZERO

func _try_special() -> void:
	# A down+special input takes priority over the delayed platform drop.
	drop_request_left = 0.0
	if core_energy < 1.0:
		special_used.emit("CORE EMPTY")
		return

	# Phase Rush only exists as a deliberate dash cancel.
	if dash_left > 0.0:
		_start_phase_rush()
		return

	var dir := special_dir_buffer if special_dir_left > 0.0 else Vector2.ZERO
	if dir.y < -0.55:
		_sky_breaker()
	elif dir.y > 0.55:
		_ground_burst()
	else:
		_core_blast()

func _spend_core(amount: float = 1.0) -> bool:
	if core_energy + 0.001 < amount:
		return false
	core_energy = maxf(core_energy - amount, 0.0)
	core_changed.emit(core_energy, core_max)
	Sfx.play("special", -7.0)
	camera_shake = maxf(camera_shake, 3.2)
	_spawn_fx(global_position, Color(0.95, 0.61, 0.08), 32.0, 0.22, 10)
	return true

func add_core(amount: float) -> void:
	if amount <= 0.0 or core_energy >= core_max:
		return
	core_energy = minf(core_energy + amount, core_max)
	core_changed.emit(core_energy, core_max)

func _core_blast() -> void:
	if not _spend_core():
		return
	var aim := aim_direction.normalized()
	if aim.length_squared() < 0.01:
		aim = Vector2(facing, 0.0)
	_spawn_player_projectile(aim, 3, 1450.0, true, 0.0)
	special_used.emit("SPECIAL // CORE BLAST")

func _sky_breaker() -> void:
	if not _spend_core():
		return
	for angle in [-0.24, -0.12, 0.0, 0.12, 0.24]:
		_spawn_player_projectile(Vector2.UP.rotated(angle), 2, 1180.0, true, 0.0)
	velocity.y = minf(velocity.y, -280.0)
	special_used.emit("SPECIAL // SKY BREAKER")

func _ground_burst() -> void:
	if not _spend_core():
		return
	var dir := Vector2(facing, 0.0)
	var bullet = _spawn_player_projectile(dir, 3, 900.0, true, 0.0)
	bullet.global_position = global_position + Vector2(facing * 38.0, 15.0)
	special_used.emit("SPECIAL // GROUND BURST")

func _nova_pulse() -> void:
	if not _spend_core():
		special_used.emit("CORE EMPTY")
		return
	for i in range(12):
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 12.0)
		var bullet = _spawn_player_projectile(dir, 1, 900.0, true, 0.0)
		bullet.lifetime = 0.32
	special_used.emit("SPECIAL // NOVA PULSE")

func _start_phase_rush() -> void:
	if not _spend_core():
		return
	var horizontal := Input.get_axis("move_left", "move_right")
	if absf(horizontal) > 0.2:
		facing = signf(horizontal)
	dash_left = 0.0
	phase_rush_left = phase_rush_duration
	phase_hit_ids.clear()
	special_used.emit("SPECIAL // PHASE RUSH")

func _damage_phase_rush_targets() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not enemy is Node2D:
			continue
		var id := enemy.get_instance_id()
		if phase_hit_ids.has(id):
			continue
		if global_position.distance_to(enemy.global_position) <= 72.0 and enemy.has_method("take_damage"):
			phase_hit_ids[id] = true
			enemy.take_damage(4, Vector2(facing * 360.0, -80.0))

func _update_aim_direction() -> void:
	if using_gamepad:
		var stick := Input.get_vector("aim_left", "aim_right", "aim_up", "aim_down")
		if stick.length() >= aim_deadzone:
			aim_direction = stick.normalized()
	else:
		var mouse_aim := global_position.direction_to(get_global_mouse_position())
		if mouse_aim.length_squared() > 0.01:
			aim_direction = mouse_aim.normalized()
	if aim_direction.x != 0.0:
		facing = signf(aim_direction.x)
	if is_instance_valid(weapon_pivot):
		weapon_pivot.rotation = aim_direction.angle()
		weapon_pivot.position = Vector2(8.0 * facing, -4.0)
		weapon_sprite.flip_v = aim_direction.x < 0.0

func _shoot() -> void:
	shot_fired.emit()
	recoil_anim = 0.12
	Sfx.play("shoot", -13.0)
	camera_shake = maxf(camera_shake, 0.8)
	var aim := aim_direction
	if aim.length_squared() < 0.01:
		aim = Vector2(facing, 0.0)
	_spawn_fx(global_position + aim.normalized() * 32.0, Color(0.95, 0.61, 0.08), 15.0, 0.10, 6)

	var angles := [0.0]
	if spread_level >= 3:
		angles = [-0.14, 0.0, 0.14]

	for angle in angles:
		_spawn_player_projectile(aim.rotated(angle), 1, 1120.0, false, 0.12)

	core_visual.rotation += 0.24

func register_hit() -> void:
	hit_confirmed.emit()

func _spawn_fx(pos: Vector2, color: Color, size: float, life: float, spokes: int) -> void:
	var fx = FX_BURST_SCENE.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = pos
	fx.setup(color, size, life, spokes)

func _spawn_player_projectile(dir: Vector2, damage: int, speed: float, special_visual: bool, core_gain: float):
	var bullet = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + dir.normalized() * 34.0
	bullet.setup(dir, false, damage, speed, self, core_gain, special_visual)
	return bullet

func _draw() -> void:
	if using_gamepad:
		var center := aim_direction.normalized() * 76.0
		var color := Color(0.25, 0.95, 1.0, 0.92)
		draw_circle(center, 10.0, Color(0.02, 0.03, 0.07, 0.75))
		draw_arc(center, 10.0, 0.0, TAU, 20, color, 2.0)
		draw_line(center + Vector2(-15, 0), center + Vector2(-6, 0), color, 2.0)
		draw_line(center + Vector2(6, 0), center + Vector2(15, 0), color, 2.0)
		draw_line(center + Vector2(0, -15), center + Vector2(0, -6), color, 2.0)
		draw_line(center + Vector2(0, 6), center + Vector2(0, 15), color, 2.0)

	if phase_rush_left > 0.0:
		draw_arc(Vector2.ZERO, 34.0, 0.0, TAU, 28, Color(1.0, 0.35, 0.8, 0.9), 5.0)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if dead or invulnerability_left > 0.0 or dash_left > 0.0 or phase_rush_left > 0.0:
		return
	health = maxi(health - amount, 0)
	damage_taken.emit(amount)
	Sfx.play("hurt", -7.0)
	camera_shake = maxf(camera_shake, 5.0)
	_spawn_fx(global_position, Color(0.85, 0.12, 0.29), 28.0, 0.18, 8)
	health_changed.emit(health, max_health)
	if health <= 0:
		dead = true
		modulate = Color(1.0, 0.25, 0.38, 1.0)
		died.emit()
		return
	invulnerability_left = 0.75
	velocity = knockback

func apply_upgrade(kind: String) -> void:
	pickup_collected.emit(kind)
	Sfx.play("pickup", -7.0)
	match kind:
		"heal":
			health = mini(health + 2, max_health)
			health_changed.emit(health, max_health)
			weapon_changed.emit("REPAIR +2")
		"rapid":
			fire_interval = 0.085
			weapon_changed.emit("WEAPON: RAPID")
		"spread":
			spread_level = 3
			weapon_changed.emit("WEAPON: SPREAD")
		"core":
			add_core(1.5)
			weapon_changed.emit("CORE RESTORED")

func set_checkpoint(new_position: Vector2) -> void:
	checkpoint_position = new_position

func _update_safe_checkpoint(delta: float) -> void:
	safe_checkpoint_left = maxf(safe_checkpoint_left - delta, 0.0)
	if safe_checkpoint_left > 0.0 or not is_on_floor() or drop_through_left > 0.0:
		return
	if not _has_safe_support_below() or _near_hazard():
		return
	checkpoint_position = global_position + Vector2(0.0, -4.0)
	safe_checkpoint_left = safe_checkpoint_interval

func _has_safe_support_below() -> bool:
	var space := get_world_2d().direct_space_state
	for offset_x in [-14.0, 14.0]:
		var from := global_position + Vector2(offset_x, 24.0)
		var to := global_position + Vector2(offset_x, 52.0)
		var query := PhysicsRayQueryParameters2D.create(from, to, 33, [get_rid()])
		query.collide_with_areas = false
		if space.intersect_ray(query).is_empty():
			return false
	return true

func _near_hazard() -> bool:
	for hazard in get_tree().get_nodes_in_group("hazards"):
		if is_instance_valid(hazard) and global_position.distance_to(hazard.global_position) < 72.0:
			return true
	return false

func _has_drop_platform_below() -> bool:
	var space := get_world_2d().direct_space_state
	var from := global_position + Vector2(0.0, 24.0)
	var to := global_position + Vector2(0.0, 54.0)
	var query := PhysicsRayQueryParameters2D.create(from, to, 32, [get_rid()])
	query.collide_with_areas = false
	return not space.intersect_ray(query).is_empty()

func _update_drop_through(delta: float) -> void:
	if drop_through_left > 0.0:
		drop_through_left = maxf(drop_through_left - delta, 0.0)
		if drop_through_left <= 0.0:
			set_collision_mask_value(6, true)

	if drop_request_left > 0.0:
		drop_request_left = maxf(drop_request_left - delta, 0.0)
		if drop_request_left <= 0.0:
			_start_drop_through()

func _start_drop_through() -> void:
	if not _has_drop_platform_below():
		return
	set_collision_mask_value(6, false)
	drop_through_left = drop_through_duration
	coyote_left = 0.0
	jump_buffer_left = 0.0
	global_position.y += 8.0
	velocity.y = maxf(velocity.y, 180.0)

func fall_respawn() -> void:
	if dead:
		return
	invulnerability_left = 0.0
	take_damage(1)
	if not dead:
		set_collision_mask_value(6, true)
		drop_through_left = 0.0
		drop_request_left = 0.0
		global_position = checkpoint_position
		velocity = Vector2.ZERO

func _update_visual() -> void:
	var step := sin(visual_time * 15.0)
	var breathe := sin(visual_time * 3.2)
	var recoil := clampf(recoil_anim / 0.12, 0.0, 1.0)

	if phase_rush_left > 0.0:
		body_visual.scale = body_visual.scale.lerp(Vector2(1.50, 0.60), 0.45)
		body_visual.rotation = lerpf(body_visual.rotation, -facing * 0.08, 0.35)
		body_visual.position.y = -2.0
		core_visual.scale = core_visual.scale.lerp(Vector2(1.45, 0.65), 0.40)
	elif dash_left > 0.0:
		body_visual.scale = body_visual.scale.lerp(Vector2(1.30, 0.72), 0.38)
		body_visual.rotation = lerpf(body_visual.rotation, -facing * 0.045, 0.30)
		body_visual.position.y = 1.0
		core_visual.scale = core_visual.scale.lerp(Vector2(1.20, 0.76), 0.30)
	elif not is_on_floor():
		body_visual.position.y = -2.0
		if velocity.y < 0.0:
			body_visual.scale = body_visual.scale.lerp(Vector2(0.91, 1.12), 0.24)
			body_visual.rotation = lerpf(body_visual.rotation, facing * 0.035, 0.22)
		else:
			body_visual.scale = body_visual.scale.lerp(Vector2(1.08, 0.92), 0.24)
			body_visual.rotation = lerpf(body_visual.rotation, -facing * 0.045, 0.22)
		core_visual.scale = core_visual.scale.lerp(Vector2(1.05, 1.05), 0.22)
	elif absf(velocity.x) > 35.0:
		var squash := absf(step) * 0.035
		body_visual.scale = body_visual.scale.lerp(Vector2(1.0 + squash, 1.0 - squash * 0.75), 0.32)
		body_visual.position.y = absf(step) * 2.6
		body_visual.rotation = lerpf(body_visual.rotation, step * 0.018 - facing * 0.018, 0.28)
		core_visual.scale = core_visual.scale.lerp(Vector2.ONE * (1.0 + absf(step) * 0.05), 0.25)
	else:
		body_visual.scale = body_visual.scale.lerp(Vector2(1.0 + breathe * 0.012, 1.0 - breathe * 0.010), 0.22)
		body_visual.position.y = breathe * 1.2
		body_visual.rotation = lerpf(body_visual.rotation, breathe * 0.008, 0.20)
		core_visual.scale = core_visual.scale.lerp(Vector2.ONE * (1.0 + breathe * 0.07), 0.20)

	authored_sprite.position.x = 0.0
	authored_sprite.position.y = -1.0
	weapon_pivot.position = Vector2(8.0 * facing, -4.0) - aim_direction.normalized() * recoil * 7.0
	weapon_pivot.position.y += body_visual.position.y * 0.35
	weapon_sprite.modulate = Color(1.0, 0.93 + recoil * 0.07, 0.82 + recoil * 0.18, 1.0)
	core_visual.modulate.a = 0.38 + (sin(visual_time * 6.0) + 1.0) * 0.20

	# Mirror the complete cutout while preserving the authored silhouette.
	body_visual.scale.x = absf(body_visual.scale.x) * facing
