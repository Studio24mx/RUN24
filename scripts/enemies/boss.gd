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
	var body_color := Color(0.88, 0.18, 0.6) if ratio > 0.33 else Color(1.0, 0.28, 0.22)
	draw_circle(Vector2.ZERO, 58.0, Color(0.05, 0.05, 0.11))
	draw_circle(Vector2.ZERO, 50.0, body_color)
	draw_circle(Vector2(-18, -12), 10.0, Color.WHITE)
	draw_circle(Vector2(18, -12), 10.0, Color.WHITE)
	draw_circle(Vector2(-18, -12), 4.0, Color(0.05, 0.05, 0.12))
	draw_circle(Vector2(18, -12), 4.0, Color(0.05, 0.05, 0.12))
	draw_arc(Vector2(0, 12), 22.0, 0.15, PI - 0.15, 18, Color(0.06, 0.06, 0.12), 6.0)
	draw_line(Vector2(-70, -32), Vector2(-48, -20), Color(0.2, 0.95, 1.0), 8.0)
	draw_line(Vector2(70, -32), Vector2(48, -20), Color(0.2, 0.95, 1.0), 8.0)
