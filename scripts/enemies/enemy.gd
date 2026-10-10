extends CharacterBody2D

signal died(enemy, room_id)

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")
const FX_BURST_SCENE := preload("res://scenes/fx/burst.tscn")
const HUSK_TEXTURE := preload("res://art/exports/enemies/husk.svg")
const VIGILANTE_TEXTURE := preload("res://art/exports/enemies/vigilante.svg")
const CENTINELA_TEXTURE := preload("res://art/exports/enemies/centinela.svg")
const CHARGER_TEXTURE := preload("res://art/exports/enemies/charger.svg")

@export_enum("walker", "turret", "flyer", "charger") var enemy_type := "walker"
@export var room_id := 1

var max_health := 4
var health := 4
var move_speed := 120.0
var fire_interval := 1.4
var fire_timer := 0.8
var gravity := 2200.0
var dead := false
var hover_time := 0.0
var hover_origin_y := 0.0
var charge_left := 0.0
var charge_cooldown_left := 1.0
var facing := 1.0
var visual_time := 0.0
var visual_sprite: Sprite2D
var recoil_left := 0.0

func _ready() -> void:
	add_to_group("enemies")
	z_index = 5
	collision_layer = 4
	collision_mask = 3
	match enemy_type:
		"walker":
			max_health = 4
			move_speed = 135.0
			visual_sprite = _add_authored_sprite(HUSK_TEXTURE, Vector2(0.52, 0.52), Vector2(0, -12))
		"turret":
			max_health = 6
			move_speed = 0.0
			fire_interval = 1.15
			visual_sprite = _add_authored_sprite(VIGILANTE_TEXTURE, Vector2(0.48, 0.48), Vector2(0, -14))
		"flyer":
			max_health = 5
			move_speed = 105.0
			fire_interval = 1.55
			visual_sprite = _add_authored_sprite(CENTINELA_TEXTURE, Vector2(0.44, 0.44), Vector2(0, -7))
		"charger":
			max_health = 18
			move_speed = 90.0
			fire_interval = 99.0
			visual_sprite = _add_authored_sprite(CHARGER_TEXTURE, Vector2(0.48, 0.48), Vector2(0, -8))
			visual_sprite.name = "ChargerArt"
			var charger_shape = $CollisionShape2D.shape.duplicate()
			charger_shape.size = Vector2(72, 58)
			$CollisionShape2D.shape = charger_shape
	health = max_health
	hover_origin_y = global_position.y
	queue_redraw()

func _add_authored_sprite(texture: Texture2D, sprite_scale: Vector2, offset: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.scale = sprite_scale
	sprite.position = offset
	sprite.z_index = 1
	add_child(sprite)
	return sprite

func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y > 880.0:
		_die()
		return
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	visual_time += delta
	recoil_left = maxf(recoil_left - delta, 0.0)
	fire_timer -= delta
	queue_redraw()
	match enemy_type:
		"walker":
			if not is_on_floor():
				velocity.y += gravity * delta
			var dx: float = player.global_position.x - global_position.x
			velocity.x = move_toward(velocity.x, signf(dx) * move_speed, 900.0 * delta)
			move_and_slide()
			_update_authored_visual()
			_damage_player_on_contact(player)
		"turret":
			velocity = Vector2.ZERO
			if global_position.distance_to(player.global_position) < 780.0 and fire_timer <= 0.0:
				_fire_at(player.global_position, 470.0)
				recoil_left = 0.16
				fire_timer = fire_interval
			_update_authored_visual()
		"flyer":
			hover_time += delta
			queue_redraw()
			var target_y := clampf(hover_origin_y + sin(hover_time * 2.2) * 42.0, 105.0, 300.0)
			var dx: float = player.global_position.x - global_position.x
			velocity.y = (target_y - global_position.y) * 3.0
			velocity.x = signf(dx) * move_speed if absf(dx) > 250.0 else 0.0
			move_and_slide()
			_update_authored_visual()
			if global_position.distance_to(player.global_position) < 850.0 and fire_timer <= 0.0:
				_fire_at(player.global_position, 420.0)
				recoil_left = 0.14
				fire_timer = fire_interval
			_damage_player_on_contact(player)
		"charger":
			if not is_on_floor():
				velocity.y += gravity * delta
			charge_cooldown_left = maxf(charge_cooldown_left - delta, 0.0)
			var dx: float = player.global_position.x - global_position.x
			if absf(dx) > 2.0:
				facing = signf(dx)
			if charge_left > 0.0:
				charge_left = maxf(charge_left - delta, 0.0)
				velocity.x = facing * 610.0
			else:
				velocity.x = move_toward(velocity.x, facing * move_speed, 650.0 * delta)
				if charge_cooldown_left <= 0.0 and absf(dx) < 650.0 and absf(player.global_position.y - global_position.y) < 130.0:
					charge_left = 0.58
					charge_cooldown_left = 2.15
					Sfx.play("dash", -5.0)
			move_and_slide()
			_update_authored_visual()
			_damage_player_on_contact(player, 2, 66.0, 620.0)
			queue_redraw()

func _update_authored_visual() -> void:
	if not is_instance_valid(visual_sprite):
		return
	match enemy_type:
		"walker":
			if absf(velocity.x) > 4.0:
				facing = signf(velocity.x)
			visual_sprite.scale.x = absf(visual_sprite.scale.x) * facing
			visual_sprite.position.y = -12.0 + sin(visual_time * 12.0) * 3.2
			visual_sprite.rotation = sin(visual_time * 12.0) * 0.035
		"turret":
			var kick := 7.0 * clampf(recoil_left / 0.16, 0.0, 1.0)
			visual_sprite.position = Vector2(-kick, -14.0 + sin(visual_time * 2.4) * 1.8)
			visual_sprite.rotation = sin(visual_time * 1.8) * 0.008
		"flyer":
			if absf(velocity.x) > 2.0:
				facing = signf(velocity.x)
			visual_sprite.scale.x = absf(visual_sprite.scale.x) * facing
			visual_sprite.scale.y = 0.44 + sin(visual_time * 10.0) * 0.022
			visual_sprite.rotation = clampf(velocity.x / 900.0, -0.10, 0.10)
		"charger":
			visual_sprite.scale.x = absf(visual_sprite.scale.x) * facing
			if charge_left > 0.0:
				visual_sprite.scale.y = lerpf(visual_sprite.scale.y, 0.40, 0.30)
				visual_sprite.scale.x = facing * 0.58
				visual_sprite.rotation = -facing * 0.055
			else:
				visual_sprite.scale.y = lerpf(visual_sprite.scale.y, 0.48, 0.18)
				visual_sprite.scale.x = facing * 0.48
				visual_sprite.rotation = sin(visual_time * 5.0) * 0.018

func _damage_player_on_contact(player: Node2D, amount: int = 1, radius: float = 48.0, push_force: float = 420.0) -> void:
	if global_position.distance_to(player.global_position) < radius and player.has_method("take_damage"):
		var push := (player.global_position - global_position).normalized() * push_force + Vector2.UP * 130.0
		player.take_damage(amount, push)

func _fire_at(target: Vector2, projectile_speed: float) -> void:
	var bullet = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position + Vector2(0, -8)
	bullet.setup(global_position.direction_to(target), true, 1, projectile_speed)

func take_damage(amount: int, knockback: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	health -= amount
	if enemy_type == "walker":
		velocity += knockback
	modulate = Color(1.0, 0.55, 0.7, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.09)
	queue_redraw()
	if health <= 0:
		_die()

func _die() -> void:
	if dead:
		return
	dead = true
	var fx = FX_BURST_SCENE.instantiate()
	get_tree().current_scene.add_child(fx)
	fx.global_position = global_position
	fx.setup(Color(0.85, 0.12, 0.29), 52.0 if enemy_type == "charger" else 32.0, 0.28, 10)
	died.emit(self, room_id)
	queue_free()

func _draw() -> void:
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var obsidian := Color(0.035, 0.045, 0.065, 1.0)
	var bone := Color(0.95, 0.90, 0.82, 1.0)
	var cochineal := Color(0.85, 0.12, 0.29, 1.0)
	var jade := Color(0.20, 0.84, 0.78, 1.0)
	var gold := Color(0.95, 0.61, 0.08, 1.0)

	# Authored sprites own the body silhouette. Procedural drawing is retained
	# below as a fallback, while only aura/telegraph/health are drawn on top.
	if is_instance_valid(visual_sprite):
		var aura_radius := 34.0
		var aura_color := jade
		if enemy_type == "walker":
			aura_radius = 31.0
			aura_color = cochineal
		elif enemy_type == "turret":
			aura_radius = 37.0
			aura_color = jade
		elif enemy_type == "flyer":
			aura_radius = 42.0 + sin(visual_time * 6.0) * 3.0
			aura_color = jade
		elif enemy_type == "charger":
			aura_radius = 60.0 + sin(visual_time * 8.0) * 4.0
			aura_color = cochineal
		draw_circle(Vector2(0, -5), aura_radius, Color(aura_color.r, aura_color.g, aura_color.b, 0.06))
		if enemy_type in ["turret", "flyer"] and fire_timer > 0.0 and fire_timer < 0.30:
			var charge := 1.0 - clampf(fire_timer / 0.30, 0.0, 1.0)
			var telegraph_color := Color(0.95, 0.61, 0.08, 0.30 + charge * 0.62)
			draw_arc(Vector2(0, -7), 34.0 + charge * 10.0, -PI * 0.85, PI * 0.85, 20, telegraph_color, 3.0 + charge * 2.0)
			draw_circle(Vector2(0, -7), 4.0 + charge * 5.0, telegraph_color)
		if enemy_type == "charger" and charge_left > 0.0:
			var charge_pulse := (sin(visual_time * 18.0) + 1.0) * 0.5
			draw_arc(Vector2(0, -5), 62.0 + charge_pulse * 5.0, -1.2, 1.2, 22, cochineal, 4.0)
			draw_line(Vector2(-facing * 92.0, 4), Vector2(-facing * 48.0, 4), gold, 5.0)
		var authored_bar_width := 72.0 if enemy_type == "charger" else 48.0
		var authored_bar_y := -68.0 if enemy_type == "charger" else -58.0
		draw_rect(Rect2(-authored_bar_width * 0.5, authored_bar_y, authored_bar_width, 4), Color(0.02, 0.025, 0.04, 0.92))
		draw_rect(Rect2(-authored_bar_width * 0.5, authored_bar_y, authored_bar_width * ratio, 4), cochineal if ratio < 0.5 else jade)
		return

	match enemy_type:
		"walker":
			# SIGNAL HUSK: broken soul reconstructed around a hot red core.
			draw_circle(Vector2(0, -5), 25.0, Color(cochineal.r, cochineal.g, cochineal.b, 0.10))
			var torso := PackedVector2Array([
				Vector2(-20, -10), Vector2(-11, -25), Vector2(9, -27),
				Vector2(21, -12), Vector2(17, 15), Vector2(-15, 17)
			])
			draw_colored_polygon(torso, obsidian)
			draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[4], torso[5], torso[0]]), cochineal, 2.5)
			# Bone mask.
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, -24), Vector2(10, -25), Vector2(16, -14),
				Vector2(8, -4), Vector2(-10, -5), Vector2(-16, -14)
			]), bone)
			draw_circle(Vector2(-6, -15), 4.5, obsidian)
			draw_circle(Vector2(7, -15), 4.5, obsidian)
			draw_circle(Vector2(0, -3), 6.0, cochineal)
			draw_circle(Vector2(0, -3), 2.0, Color.WHITE)
			# Limbs.
			draw_line(Vector2(-12, 12), Vector2(-17, 30), obsidian, 8.0)
			draw_line(Vector2(10, 12), Vector2(15, 30), obsidian, 8.0)
			draw_line(Vector2(-19, 1), Vector2(-30, 10), bone, 5.0)
			draw_line(Vector2(18, 0), Vector2(31, -6), bone, 5.0)
			draw_line(Vector2(-17, 30), Vector2(-7, 30), jade, 3.0)
			draw_line(Vector2(15, 30), Vector2(25, 30), jade, 3.0)

		"turret":
			# VIGILANTE: shrine/drone hybrid with a single signal eye.
			draw_circle(Vector2(-2, -4), 32.0, Color(jade.r, jade.g, jade.b, 0.07))
			var body_pts := PackedVector2Array([
				Vector2(-26, 18), Vector2(-24, -12), Vector2(-12, -29),
				Vector2(8, -31), Vector2(22, -16), Vector2(26, 18)
			])
			draw_colored_polygon(body_pts, obsidian)
			draw_polyline(PackedVector2Array([body_pts[0], body_pts[1], body_pts[2], body_pts[3], body_pts[4], body_pts[5], body_pts[0]]), jade, 2.6)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-13, -22), Vector2(8, -24), Vector2(15, -14),
				Vector2(7, -6), Vector2(-10, -7), Vector2(-17, -15)
			]), bone)
			draw_circle(Vector2(-1, -15), 8.0, cochineal)
			draw_circle(Vector2(-1, -15), 3.0, Color.WHITE)
			# Barrel.
			draw_rect(Rect2(10, -8, 34, 11), obsidian)
			draw_rect(Rect2(34, -6, 12, 7), cochineal)
			draw_line(Vector2(-19, 9), Vector2(-28, 23), gold, 3.0)
			draw_line(Vector2(17, 9), Vector2(27, 23), gold, 3.0)

		"flyer":
			# CINTINELA: airborne soul-router with asymmetric spirit wings.
			var pulse := (sin(hover_time * 5.0) + 1.0) * 0.5
			draw_circle(Vector2.ZERO, 37.0 + pulse * 4.0, Color(jade.r, jade.g, jade.b, 0.08))
			var left_wing := PackedVector2Array([Vector2(-15, -4), Vector2(-52, -24), Vector2(-42, 11), Vector2(-19, 17)])
			var right_wing := PackedVector2Array([Vector2(16, -4), Vector2(50, -17), Vector2(44, 20), Vector2(19, 16)])
			draw_colored_polygon(left_wing, obsidian)
			draw_colored_polygon(right_wing, obsidian)
			draw_polyline(PackedVector2Array([left_wing[0], left_wing[1], left_wing[2], left_wing[3], left_wing[0]]), jade, 3.0)
			draw_polyline(PackedVector2Array([right_wing[0], right_wing[1], right_wing[2], right_wing[3], right_wing[0]]), cochineal, 3.0)
			draw_circle(Vector2.ZERO, 24.0, obsidian)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-12, -18), Vector2(11, -18), Vector2(17, -3),
				Vector2(8, 13), Vector2(-9, 13), Vector2(-17, -3)
			]), bone)
			draw_circle(Vector2(0, -5), 7.0, cochineal)
			draw_circle(Vector2(0, -5), 2.5, Color.WHITE)
			draw_colored_polygon(PackedVector2Array([
				Vector2(-7, 25), Vector2(7, 25), Vector2(0, 40)
			]), Color(jade.r, jade.g, jade.b, 0.75))

		"charger":
			var charge_pulse := (sin(Time.get_ticks_msec() * 0.018) + 1.0) * 0.5
			var aura_alpha := 0.16 + charge_pulse * 0.16 if charge_left > 0.0 else 0.06
			draw_circle(Vector2(0, -4), 58.0 + charge_pulse * 5.0, Color(cochineal.r, cochineal.g, cochineal.b, aura_alpha))
			if charge_left > 0.0:
				draw_line(Vector2(-facing * 78.0, -5), Vector2(-facing * 42.0, -5), cochineal, 7.0)
				draw_line(Vector2(-facing * 92.0, 8), Vector2(-facing * 55.0, 8), gold, 4.0)

	# Compact diegetic health trace.
	var bar_width := 72.0 if enemy_type == "charger" else 48.0
	var bar_y := -58.0 if enemy_type == "charger" else -42.0
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width, 4), Color(0.02, 0.025, 0.04, 0.92))
	draw_rect(Rect2(-bar_width * 0.5, bar_y, bar_width * ratio, 4), cochineal if ratio < 0.5 else jade)
