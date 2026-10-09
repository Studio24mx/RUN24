extends CharacterBody2D

signal died(enemy, room_id)

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")

@export_enum("walker", "turret", "flyer") var enemy_type := "walker"
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

func _ready() -> void:
	add_to_group("enemies")
	z_index = 5
	collision_layer = 4
	collision_mask = 3
	match enemy_type:
		"walker":
			max_health = 4
			move_speed = 135.0
		"turret":
			max_health = 6
			move_speed = 0.0
			fire_interval = 1.15
		"flyer":
			max_health = 5
			move_speed = 105.0
			fire_interval = 1.55
	health = max_health
	hover_origin_y = global_position.y
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		return
	if global_position.y > 880.0:
		_die()
		return
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	fire_timer -= delta
	match enemy_type:
		"walker":
			if not is_on_floor():
				velocity.y += gravity * delta
			var dx: float = player.global_position.x - global_position.x
			velocity.x = move_toward(velocity.x, signf(dx) * move_speed, 900.0 * delta)
			move_and_slide()
			_damage_player_on_contact(player)
		"turret":
			velocity = Vector2.ZERO
			if global_position.distance_to(player.global_position) < 780.0 and fire_timer <= 0.0:
				_fire_at(player.global_position, 470.0)
				fire_timer = fire_interval
		"flyer":
			hover_time += delta
			queue_redraw()
			var target_y := clampf(hover_origin_y + sin(hover_time * 2.2) * 42.0, 105.0, 300.0)
			global_position.y = lerpf(global_position.y, target_y, 3.0 * delta)
			var dx: float = player.global_position.x - global_position.x
			if absf(dx) > 250.0:
				global_position.x += signf(dx) * move_speed * delta
			if global_position.distance_to(player.global_position) < 850.0 and fire_timer <= 0.0:
				_fire_at(player.global_position, 420.0)
				fire_timer = fire_interval
			_damage_player_on_contact(player)

func _damage_player_on_contact(player: Node2D) -> void:
	if global_position.distance_to(player.global_position) < 48.0 and player.has_method("take_damage"):
		var push := (player.global_position - global_position).normalized() * 420.0 + Vector2.UP * 130.0
		player.take_damage(1, push)

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
	died.emit(self, room_id)
	queue_free()

func _draw() -> void:
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var obsidian := Color(0.035, 0.045, 0.065, 1.0)
	var bone := Color(0.95, 0.90, 0.82, 1.0)
	var cochineal := Color(0.85, 0.12, 0.29, 1.0)
	var jade := Color(0.20, 0.84, 0.78, 1.0)
	var gold := Color(0.95, 0.61, 0.08, 1.0)

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

	# Compact diegetic health trace.
	draw_rect(Rect2(-24, -42, 48, 4), Color(0.02, 0.025, 0.04, 0.92))
	draw_rect(Rect2(-24, -42, 48.0 * ratio, 4), cochineal if ratio < 0.5 else jade)
