extends CharacterBody2D

const FX_BURST_SCENE := preload("res://scenes/fx/burst.tscn")

var direction := Vector2.RIGHT
var speed := 1000.0
var damage := 1
var enemy_owned := false
var lifetime := 2.5
var source_player: Node = null
var core_gain_on_hit := 0.0
var special_visual := false

func setup(
	new_direction: Vector2,
	is_enemy: bool,
	new_damage: int = 1,
	new_speed: float = 1000.0,
	source: Node = null,
	core_gain: float = 0.0,
	is_special: bool = false
) -> void:
	direction = new_direction.normalized()
	enemy_owned = is_enemy
	damage = new_damage
	speed = new_speed
	source_player = source
	core_gain_on_hit = core_gain
	special_visual = is_special

	if special_visual:
		scale = Vector2(1.7, 1.7)
		lifetime = 1.5

	if enemy_owned:
		collision_layer = 16
		# World (1) + player (2) + projectile-only platform blockers (64).
		collision_mask = 67
	else:
		collision_layer = 8
		# World (1) + enemies (4) + projectile-only platform blockers (64).
		collision_mask = 69
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	# Player shots only exist while they remain inside the current camera view.
	# This prevents damaging enemies the player cannot currently see.
	if not enemy_owned and _outside_player_view():
		queue_free()
		return

	var collision := move_and_collide(direction * speed * delta)
	if collision:
		var body := collision.get_collider()
		if body and body.has_method("take_damage"):
			if enemy_owned and body.is_in_group("player"):
				body.take_damage(damage, direction * 320.0 + Vector2.UP * 80.0)
			elif not enemy_owned and body.is_in_group("enemies"):
				# Damage only if the target is actually in the player's current field of view.
				# A small margin counts partially visible enemy bodies as visible.
				if _point_in_player_view(body.global_position, 42.0):
					body.take_damage(damage, direction * 180.0)
					Sfx.play("hit", -12.0)
					if is_instance_valid(source_player) and source_player.has_method("register_hit"):
						source_player.register_hit()
					if core_gain_on_hit > 0.0 and is_instance_valid(source_player) and source_player.has_method("add_core"):
						source_player.add_core(core_gain_on_hit)
		var fx = FX_BURST_SCENE.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = collision.get_position()
		var impact_color := Color(0.85, 0.12, 0.29) if enemy_owned else Color(0.20, 0.84, 0.78)
		fx.setup(impact_color, 13.0 if not special_visual else 24.0, 0.14, 6)
		queue_free()

func _outside_player_view() -> bool:
	return not _point_in_player_view(global_position, 0.0)

func _point_in_player_view(point: Vector2, margin_value: float) -> bool:
	var camera := get_viewport().get_camera_2d()
	if not is_instance_valid(camera):
		return true
	var viewport_size := get_viewport().get_visible_rect().size
	var zoom := camera.zoom
	var half_size := Vector2(
		viewport_size.x / maxf(zoom.x, 0.001),
		viewport_size.y / maxf(zoom.y, 0.001)
	) * 0.5
	var margin := Vector2(margin_value, margin_value)
	var center := camera.get_screen_center_position()
	var visible_rect := Rect2(center - half_size - margin, half_size * 2.0 + margin * 2.0)
	return visible_rect.has_point(point)

func _draw() -> void:
	if special_visual and not enemy_owned:
		var c := Color(0.95, 0.61, 0.08, 1.0)
		draw_circle(Vector2.ZERO, 9.0, Color(0.04, 0.04, 0.09, 0.95))
		draw_circle(Vector2.ZERO, 7.0, c)
		draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		draw_line(-direction * 17.0, Vector2.ZERO, c, 5.0)
		return

	var c := Color(0.85, 0.12, 0.29, 1.0) if enemy_owned else Color(0.20, 0.84, 0.78, 1.0)
	draw_circle(Vector2.ZERO, 7.0, c)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	draw_line(-direction * 13.0, Vector2.ZERO, c, 4.0)
