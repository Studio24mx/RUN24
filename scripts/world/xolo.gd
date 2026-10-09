extends Node2D

var player: Node2D
var hover_time := 0.0
var follow_velocity := Vector2.ZERO
var last_facing := 1.0

func _ready() -> void:
	z_index = 4
	queue_redraw()

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return

	hover_time += delta
	last_facing = player.facing

	var behind := -last_facing * 72.0
	var target := player.global_position + Vector2(behind, -18.0 + sin(hover_time * 3.2) * 5.0)
	var distance := global_position.distance_to(target)
	if distance > 320.0:
		global_position = target
		follow_velocity = Vector2.ZERO
	else:
		var stiffness := 18.0
		var damping := 7.5
		var acceleration := (target - global_position) * stiffness - follow_velocity * damping
		follow_velocity += acceleration * delta
		global_position += follow_velocity * delta

	scale.x = absf(scale.x) * (-1.0 if last_facing < 0.0 else 1.0)
	queue_redraw()

func _draw() -> void:
	var pulse := (sin(hover_time * 5.0) + 1.0) * 0.5
	var obsidian := Color(0.035, 0.045, 0.065, 1.0)
	var bone := Color(0.95, 0.90, 0.82, 1.0)
	var jade := Color(0.20, 0.84, 0.78, 1.0)
	var cochineal := Color(0.85, 0.18, 0.35, 1.0)

	# Spirit aura.
	draw_circle(Vector2(-4, -3), 30.0 + pulse * 3.0, Color(jade.r, jade.g, jade.b, 0.07))
	draw_arc(Vector2(-4, -3), 27.0 + pulse * 2.0, -2.4, 1.0, 22, Color(jade.r, jade.g, jade.b, 0.32), 2.0)

	# Tail / signal flame.
	var tail := PackedVector2Array([
		Vector2(-28, 1),
		Vector2(-42, -7 - pulse * 5.0),
		Vector2(-50, -20),
		Vector2(-55, -7),
		Vector2(-46, 7),
		Vector2(-34, 11)
	])
	draw_colored_polygon(tail, Color(jade.r, jade.g, jade.b, 0.60))

	# Body silhouette.
	var torso := PackedVector2Array([
		Vector2(-24, -10), Vector2(8, -13), Vector2(23, -4),
		Vector2(17, 10), Vector2(-18, 12), Vector2(-29, 4)
	])
	draw_colored_polygon(torso, obsidian)
	draw_polyline(PackedVector2Array([torso[0], torso[1], torso[2], torso[3], torso[4], torso[5], torso[0]]), jade, 2.2)

	# Legs.
	for x in [-15.0, 6.0, 17.0]:
		draw_line(Vector2(x, 7), Vector2(x - 2, 20), obsidian, 6.0)
		draw_line(Vector2(x, 7), Vector2(x - 2, 20), jade, 1.7)
		draw_line(Vector2(x - 2, 20), Vector2(x + 5, 20), bone, 2.4)

	# Neck and head.
	draw_line(Vector2(14, -8), Vector2(22, -21), obsidian, 8.0)
	var head := PackedVector2Array([
		Vector2(17, -28), Vector2(31, -32), Vector2(40, -25),
		Vector2(36, -14), Vector2(23, -14), Vector2(15, -20)
	])
	draw_colored_polygon(head, obsidian)
	draw_polyline(PackedVector2Array([head[0], head[1], head[2], head[3], head[4], head[5], head[0]]), jade, 2.0)

	# Tall ears.
	draw_colored_polygon(PackedVector2Array([Vector2(21, -29), Vector2(22, -47), Vector2(28, -31)]), obsidian)
	draw_colored_polygon(PackedVector2Array([Vector2(31, -31), Vector2(37, -46), Vector2(38, -27)]), obsidian)
	draw_line(Vector2(22, -46), Vector2(27, -31), jade, 1.5)
	draw_line(Vector2(37, -45), Vector2(37, -28), jade, 1.5)

	# Bone markings / ribs.
	for i in range(4):
		var x := -15.0 + float(i) * 7.0
		draw_line(Vector2(x, -6), Vector2(x + 1, 7), bone, 2.0)
	draw_line(Vector2(-19, 0), Vector2(11, 0), bone, 2.0)

	# Eye + scarf.
	draw_circle(Vector2(30, -24), 3.2, jade)
	draw_circle(Vector2(30, -24), 1.2, Color.WHITE)
	draw_line(Vector2(14, -15), Vector2(3, -18), cochineal, 5.0)
	draw_line(Vector2(7, -17), Vector2(-2, -24 - pulse * 2.0), cochineal, 3.0)

	# Floating soul flame.
	var flame_center := Vector2(-8, -39)
	draw_circle(flame_center, 4.0 + pulse, jade)
	draw_colored_polygon(PackedVector2Array([
		flame_center + Vector2(-4, 0),
		flame_center + Vector2(0, -11 - pulse * 3.0),
		flame_center + Vector2(5, 0),
		flame_center + Vector2(0, 6)
	]), Color(jade.r, jade.g, jade.b, 0.72))
