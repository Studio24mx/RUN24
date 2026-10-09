extends Area2D

@export_enum("heal", "rapid", "spread", "core") var kind := "heal"

var start_y := 0.0
var time := 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	start_y = global_position.y
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _process(delta: float) -> void:
	time += delta
	global_position.y = start_y + sin(time * 3.0) * 10.0
	rotation = sin(time * 2.0) * 0.06
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("apply_upgrade"):
		body.apply_upgrade(kind)
		queue_free()

func _draw() -> void:
	var c := Color(0.20, 0.84, 0.78)
	if kind == "rapid":
		c = Color(0.95, 0.61, 0.08)
	elif kind == "spread":
		c = Color(0.85, 0.12, 0.29)
	elif kind == "core":
		c = Color(0.95, 0.61, 0.08)

	var pulse := (sin(time * 5.0) + 1.0) * 0.5
	draw_circle(Vector2.ZERO, 34.0 + pulse * 5.0, Color(c.r, c.g, c.b, 0.10))
	draw_circle(Vector2.ZERO, 29.0, Color(0.02, 0.025, 0.06, 0.98))
	draw_arc(Vector2.ZERO, 27.0, 0.0, TAU, 32, Color.WHITE, 3.0)
	draw_arc(Vector2.ZERO, 23.0, 0.0, TAU, 32, c, 5.0)

	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var a := Vector2.RIGHT.rotated(angle)
		draw_line(a * 32.0, a * (39.0 + pulse * 3.0), c, 4.0)

	if kind == "heal":
		draw_rect(Rect2(-6, -16, 12, 32), Color.WHITE)
		draw_rect(Rect2(-16, -6, 32, 12), Color.WHITE)
		draw_rect(Rect2(-4, -14, 8, 28), c)
		draw_rect(Rect2(-14, -4, 28, 8), c)
	elif kind == "rapid":
		draw_polygon(
			PackedVector2Array([
				Vector2(-9, -16), Vector2(8, -16), Vector2(1, -3),
				Vector2(12, -3), Vector2(-8, 17), Vector2(-2, 4), Vector2(-14, 4)
			]),
			PackedColorArray([c])
		)
		draw_polyline(
			PackedVector2Array([
				Vector2(-9, -16), Vector2(8, -16), Vector2(1, -3),
				Vector2(12, -3), Vector2(-8, 17)
			]),
			Color.WHITE,
			2.0
		)
	elif kind == "spread":
		draw_line(Vector2(-15, 11), Vector2(0, -14), Color.WHITE, 8.0)
		draw_line(Vector2(0, -14), Vector2(15, 11), Color.WHITE, 8.0)
		draw_line(Vector2(-15, 11), Vector2(0, -14), c, 4.0)
		draw_line(Vector2(0, -14), Vector2(15, 11), c, 4.0)
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
	else:
		var diamond := PackedVector2Array([Vector2(0, -16), Vector2(14, 0), Vector2(0, 16), Vector2(-14, 0)])
		draw_colored_polygon(diamond, c)
		draw_polyline(PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]]), Color.WHITE, 2.0)
		draw_circle(Vector2.ZERO, 4.0, Color.WHITE)
