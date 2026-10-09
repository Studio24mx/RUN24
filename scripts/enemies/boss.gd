extends CharacterBody2D

signal died
signal health_changed(current, maximum)

const PROJECTILE_SCENE := preload("res://scenes/combat/projectile.tscn")
const FX_BURST_SCENE := preload("res://scenes/fx/burst.tscn")

@export var arena_center_x := 4580.0
var max_health := 220
var health := 220
var active := false
var dead := false
var time := 0.0
var fire_timer := 0.8
var pattern_index := 0

@onready var authored_body: Sprite2D = $AuthoredBody

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("boss")
	collision_layer = 4
	collision_mask = 3
	modulate.a = 0.0
	scale = Vector2(0.72, 0.72)
	queue_redraw()

func activate() -> void:
	if active or dead:
		return
	active = true
	fire_timer = 1.45
	var intro := create_tween()
	intro.set_parallel(true)
	intro.set_trans(Tween.TRANS_BACK)
	intro.set_ease(Tween.EASE_OUT)
	intro.tween_property(self, "modulate:a", 1.0, 0.65)
	intro.tween_property(self, "scale", Vector2.ONE, 0.75)
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
	var phase_energy := 1.0 - ratio
	if is_instance_valid(authored_body):
		authored_body.rotation = sin(time * (1.5 + phase_energy * 2.0)) * (0.012 + phase_energy * 0.025)
		var pulse_scale := 0.45 + sin(time * 4.0) * (0.006 + phase_energy * 0.012)
		authored_body.scale = Vector2.ONE * pulse_scale
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
	Sfx.play("shoot", -8.0)
	var base_dir := global_position.direction_to(target)
	var center := float(count - 1) * 0.5
	for i in range(count):
		var angle := (float(i) - center) * spread
		_spawn_bullet(base_dir.rotated(angle), projectile_speed)

func _radial_burst(count: int, projectile_speed: float) -> void:
	Sfx.play("shoot", -8.0)
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
		for size in [70.0, 110.0, 150.0]:
			var fx = FX_BURST_SCENE.instantiate()
			get_tree().current_scene.add_child(fx)
			fx.global_position = global_position
			fx.setup(Color(0.95, 0.61, 0.08), size, 0.45, 14)
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

	# Procedural broadcast halo stays alive around the authored SVG body.
	draw_circle(Vector2.ZERO, 88.0 + pulse * 4.0, Color(cochineal.r, cochineal.g, cochineal.b, 0.055))
	draw_arc(Vector2.ZERO, 79.0, 0.0, TAU, 48, Color(cochineal.r, cochineal.g, cochineal.b, 0.82), 5.0)
	draw_arc(Vector2.ZERO, 68.0, time * 0.2, time * 0.2 + PI * 1.45, 38, Color(jade.r, jade.g, jade.b, 0.52), 2.0)

	for i in range(12):
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / 12.0 + time * 0.08)
		var inner := dir * 84.0
		var outer := dir * (98.0 + 6.0 * sin(time * 3.0 + float(i)))
		draw_line(inner, outer, cochineal if i % 2 == 0 else bone, 3.0)

	# Four signal arms remain procedural so attack phases feel alive.
	for i in range(4):
		var side := -1.0 if i < 2 else 1.0
		var row := float(i % 2)
		var shoulder := Vector2(side * 34.0, -18.0 + row * 30.0)
		var elbow := Vector2(side * (72.0 + row * 10.0), -42.0 + row * 52.0)
		var hand := Vector2(side * (105.0 + row * 7.0), -65.0 + row * 64.0)
		draw_line(shoulder, elbow, obsidian, 12.0)
		draw_line(elbow, hand, obsidian, 10.0)
		draw_line(shoulder, elbow, cochineal, 3.0)
		draw_line(elbow, hand, cochineal, 3.0)
		draw_circle(hand, 6.0, bone)

	# External core aura communicates phase/health without repainting the SVG.
	var core_color := gold if ratio > 0.33 else cochineal
	draw_circle(Vector2(0, 15), 17.0 + pulse * 2.0, Color(core_color.r, core_color.g, core_color.b, 0.10))
	if fire_timer < 0.22:
		draw_arc(Vector2.ZERO, 104.0 + pulse * 4.0, 0.0, TAU, 48, Color(gold.r, gold.g, gold.b, 0.78), 4.0)
