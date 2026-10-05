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
	match enemy_type:
		"walker":
			draw_circle(Vector2(0, -5), 22.0, Color(1.0, 0.18, 0.55))
			draw_rect(Rect2(-18, 12, 14, 10), Color(0.12, 0.9, 0.92))
			draw_rect(Rect2(4, 12, 14, 10), Color(0.12, 0.9, 0.92))
			draw_circle(Vector2(-7, -9), 4.0, Color.WHITE)
			draw_circle(Vector2(7, -9), 4.0, Color.WHITE)
		"turret":
			var pts := PackedVector2Array([Vector2(-24, 18), Vector2(-20, -18), Vector2(0, -28), Vector2(20, -18), Vector2(24, 18)])
			draw_colored_polygon(pts, Color(0.15, 0.8, 1.0))
			draw_rect(Rect2(0, -7, 32, 10), Color(1.0, 0.34, 0.63))
			draw_circle(Vector2(-6, -7), 5.0, Color.WHITE)
		"flyer":
			var pulse := (sin(hover_time * 5.0) + 1.0) * 0.5
			# Halo y silueta oscura para separarlo del fondo.
			draw_circle(Vector2.ZERO, 35.0 + pulse * 3.0, Color(0.2, 0.95, 1.0, 0.09))
			draw_circle(Vector2.ZERO, 29.0, Color(0.025, 0.03, 0.07, 0.98))
			# Alas grandes con borde luminoso.
			var left_wing := PackedVector2Array([Vector2(-20, -3), Vector2(-54, -20), Vector2(-48, 18), Vector2(-22, 10)])
			var right_wing := PackedVector2Array([Vector2(20, -3), Vector2(54, -20), Vector2(48, 18), Vector2(22, 10)])
			draw_colored_polygon(left_wing, Color(0.03, 0.04, 0.09))
			draw_colored_polygon(right_wing, Color(0.03, 0.04, 0.09))
			draw_polyline(PackedVector2Array([Vector2(-20, -3), Vector2(-54, -20), Vector2(-48, 18), Vector2(-22, 10), Vector2(-20, -3)]), Color(0.15, 0.95, 1.0), 5.0)
			draw_polyline(PackedVector2Array([Vector2(20, -3), Vector2(54, -20), Vector2(48, 18), Vector2(22, 10), Vector2(20, -3)]), Color(1.0, 0.25, 0.68), 5.0)
			# Cuerpo con doble contraste.
			draw_circle(Vector2.ZERO, 25.0, Color(0.04, 0.04, 0.10))
			draw_circle(Vector2.ZERO, 21.0, Color(1.0, 0.82, 0.12))
			draw_arc(Vector2.ZERO, 25.0, 0.0, TAU, 28, Color.WHITE, 2.5)
			draw_circle(Vector2(0, -5), 7.0, Color.WHITE)
			draw_circle(Vector2(0, -5), 3.5, Color(0.08, 0.08, 0.15))
			# Marcador inferior para leer su posición durante el combate.
			draw_polygon(PackedVector2Array([Vector2(-8, 31), Vector2(8, 31), Vector2(0, 42)]), PackedColorArray([Color(1.0, 0.3, 0.65)]))
	draw_rect(Rect2(-24, -39, 48, 5), Color(0.08, 0.08, 0.12, 0.9))
	draw_rect(Rect2(-24, -39, 48.0 * ratio, 5), Color(0.25, 1.0, 0.55))
