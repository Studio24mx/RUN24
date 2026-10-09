extends Node2D

var fx_color := Color.WHITE
var radius := 20.0
var duration := 0.24
var age := 0.0
var spoke_count := 8

func setup(new_color: Color, new_radius: float = 20.0, new_duration: float = 0.24, new_spokes: int = 8) -> void:
	fx_color = new_color
	radius = new_radius
	duration = new_duration
	spoke_count = new_spokes
	z_index = 12
	queue_redraw()

func _process(delta: float) -> void:
	age += delta
	if age >= duration:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var t := clampf(age / maxf(duration, 0.001), 0.0, 1.0)
	var fade := 1.0 - t
	var current_radius := radius * (0.25 + t * 0.95)
	draw_circle(Vector2.ZERO, maxf(2.0, radius * 0.22 * fade), Color(fx_color.r, fx_color.g, fx_color.b, fade * 0.7))
	draw_arc(Vector2.ZERO, current_radius * 0.55, 0.0, TAU, 24, Color(fx_color.r, fx_color.g, fx_color.b, fade * 0.7), 2.0 + fade * 2.0)
	for i in range(spoke_count):
		var dir := Vector2.RIGHT.rotated(TAU * float(i) / float(maxi(spoke_count, 1)) + 0.17)
		var inner := dir * current_radius * 0.32
		var outer := dir * current_radius
		draw_line(inner, outer, Color(fx_color.r, fx_color.g, fx_color.b, fade), 1.5 + fade * 3.0)
