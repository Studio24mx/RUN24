extends CharacterBody2D

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
		collision_mask = 3
	else:
		collision_layer = 8
		collision_mask = 5
	queue_redraw()

func _physics_process(delta: float) -> void:
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return

	var collision := move_and_collide(direction * speed * delta)
	if collision:
		var body := collision.get_collider()
		if body and body.has_method("take_damage"):
			if enemy_owned and body.is_in_group("player"):
				body.take_damage(damage, direction * 320.0 + Vector2.UP * 80.0)
			elif not enemy_owned and body.is_in_group("enemies"):
				body.take_damage(damage, direction * 180.0)
				if core_gain_on_hit > 0.0 and is_instance_valid(source_player) and source_player.has_method("add_core"):
					source_player.add_core(core_gain_on_hit)
		queue_free()

func _draw() -> void:
	if special_visual and not enemy_owned:
		var c := Color(1.0, 0.72, 0.18, 1.0)
		draw_circle(Vector2.ZERO, 9.0, Color(0.04, 0.04, 0.09, 0.95))
		draw_circle(Vector2.ZERO, 7.0, c)
		draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
		draw_line(-direction * 17.0, Vector2.ZERO, c, 5.0)
		return

	var c := Color(1.0, 0.32, 0.62, 1.0) if enemy_owned else Color(0.25, 0.95, 1.0, 1.0)
	draw_circle(Vector2.ZERO, 7.0, c)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
	draw_line(-direction * 13.0, Vector2.ZERO, c, 4.0)
