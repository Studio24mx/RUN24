extends CharacterBody2D

signal died
signal health_changed(current, maximum)

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")

@export var arena_center_x := 4580.0
var max_health := 80
var health := 80
var active := false
var dead := false
var time := 0.0
var fire_timer := 0.8
var pattern_index := 0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 3
	queue_redraw()

func activate() -> void:
	if active or dead:
		return
	active = true
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if not active or dead:
		return
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return

	time += delta
	queue_redraw()
	fire_timer -= delta
	var ratio := float(health) / float(max_health)
	var movement_speed := 1.4 if ratio > 0.5 else 2.0
	global_position.x = arena_center_x + sin(time * movement_speed) * 260.0
	global_position.y = 300.0 + sin(time * 2.1) * 70.0

	if fire_timer <= 0.0:
		if ratio > 0.66:
			_aimed_burst(player.global_position, 3, 0.13, 520.0)
			fire_timer = 1.05
		elif ratio > 0.33:
			if pattern_index % 2 == 0:
				_radial_burst(10, 390.0)
			else:
				_aimed_burst(player.global_position, 5, 0.16, 560.0)
			pattern_index += 1
			fire_timer = 0.85
		else:
			_radial_burst(14, 470.0)
			_aimed_burst(player.global_position, 3, 0.10, 620.0)
			fire_timer = 0.68

	if global_position.distance_to(player.global_position) < 76.0 and player.has_method("take_damage"):
		player.take_damage(1, global_position.direction_to(player.global_position) * 560.0 + Vector2.UP * 160.0)

func _aimed_burst(target: Vector2, count: int, spread: float, projectile_speed: float) -> void:
	var base_dir := global_position.direction_to(target)
	var center := float(count - 1) * 0.5
	for i in range(count):
		var angle := (float(i) - center) * spread
		_spawn_bullet(base_dir.rotated(angle), projectile_speed)

func _radial_burst(count: int, projectile_speed: float) -> void:
	for i in range(count):
		var angle := TAU * float(i) / float(count) + time * 0.35
		_spawn_bullet(Vector2.RIGHT.rotated(angle), projectile_speed)

func _spawn_bullet(dir: Vector2, projectile_speed: float) -> void:
	var bullet = PROJECTILE_SCENE.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = global_position
	bullet.setup(dir, true, 1, projectile_speed)

func take_damage(amount: int, _knockback: Vector2 = Vector2.ZERO) -> void:
	if not active or dead:
		return
	health -= amount
	health_changed.emit(maxi(health, 0), max_health)
	modulate = Color(1.0, 0.45, 0.65, 1.0)
	var tween := create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.08)
	queue_redraw()
	if health <= 0:
		dead = true
		died.emit()
		queue_free()

func _draw() -> void:
	var ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	var obsidian := Color(0.025, 0.032, 0.050, 1.0)
	var bone := Color(0.95, 0.90, 0.82, 1.0)
	var cochineal := Color(0.85, 0.12, 0.29, 1.0)
	var jade := Color(0.20, 0.84, 0.78, 1.0)
	var gold := Color(0.95, 0.61, 0.08, 1.0)
	var pulse := (sin(time * 4.0) + 1.0) * 0.5

	# THE IDOL: artificial star / broadcast saint.
	draw_circle(Vector2.ZERO, 86.0 + pulse * 4.0, Color(cochineal.r, cochineal.g, cochineal.b, 0.06))
	draw_arc(Vector2.ZERO, 77.0, 0.0, TAU, 48, Color(cochineal.r, cochineal.g, cochineal.b, 0.85), 5.0)
	draw_arc(Vector2.ZERO, 66.0, time * 0.2, time * 0.2 + PI * 1.45, 38, Color(jade.r, jade.g, jade.b, 0.55), 2.0)

	# Radial broadcast spikes.
	for i in range(12):
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 12.0 + time * 0.08)
		var inner := dir * 82.0
		var outer := dir * (96.0 + 6.0 * sin(time * 3.0 + float(i)))
		draw_line(inner, outer, cochineal if i % 2 == 0 else bone, 3.0)

	# Multi-arm silhouette.
	for i in range(4):
		var side := -1.0 if i < 2 else 1.0
		var row := float(i % 2)
		var shoulder := Vector2(side * 36.0, -18.0 + row * 31.0)
		var elbow := Vector2(side * (72.0 + row * 10.0), -42.0 + row * 52.0)
		var hand := Vector2(side * (105.0 + row * 7.0), -65.0 + row * 64.0)
		draw_line(shoulder, elbow, obsidian, 12.0)
		draw_line(elbow, hand, obsidian, 10.0)
		draw_line(shoulder, elbow, cochineal, 3.0)
		draw_line(elbow, hand, cochineal, 3.0)
		draw_circle(hand, 6.0, bone)

	# Robed central body.
	var robe := PackedVector2Array([
		Vector2(-34, -24), Vector2(31, -24), Vector2(40, 48),
		Vector2(22, 73), Vector2(-23, 73), Vector2(-40, 48)
	])
	draw_colored_polygon(robe, obsidian)
	draw_polyline(PackedVector2Array([robe[0], robe[1], robe[2], robe[3], robe[4], robe[5], robe[0]]), cochineal, 3.5)
	draw_line(Vector2(0, 4), Vector2(0, 65), jade, 3.0)
	draw_line(Vector2(-20, 39), Vector2(20, 39), Color(jade.r, jade.g, jade.b, 0.5), 2.0)

	# Bone broadcast mask.
	var mask := PackedVector2Array([
		Vector2(-24, -43), Vector2(-10, -57), Vector2(10, -57),
		Vector2(25, -43), Vector2(22, -17), Vector2(11, -4),
		Vector2(0, 4), Vector2(-12, -4), Vector2(-23, -18)
	])
	draw_colored_polygon(mask, bone)
	draw_circle(Vector2(-9, -35), 6.5, obsidian)
	draw_circle(Vector2(10, -35), 6.5, obsidian)
	draw_circle(Vector2(-9, -35), 2.2, cochineal)
	draw_circle(Vector2(10, -35), 2.2, cochineal)
	draw_colored_polygon(PackedVector2Array([
		Vector2(-4, -24), Vector2(4, -24), Vector2(0, -15)
	]), obsidian)
	for x in [-10.0, -4.0, 3.0, 9.0]:
		draw_line(Vector2(x, -10), Vector2(x, -3), obsidian, 2.2)

	# Crown / antenna.
	draw_line(Vector2(-18, -54), Vector2(-31, -78), cochineal, 4.0)
	draw_line(Vector2(0, -58), Vector2(0, -86), gold, 4.0)
	draw_line(Vector2(18, -54), Vector2(31, -78), cochineal, 4.0)
	draw_circle(Vector2(0, -89), 5.0 + pulse * 2.0, gold)

	# Exposed signal core changes toward critical red.
	var core_color := gold if ratio > 0.33 else cochineal
	draw_circle(Vector2(0, 18), 13.0, Color(0.02, 0.025, 0.04))
	draw_circle(Vector2(0, 18), 9.0 + pulse * 1.5, core_color)
	draw_circle(Vector2(0, 18), 3.0, Color.WHITE)
