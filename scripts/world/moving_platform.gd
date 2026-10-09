extends AnimatableBody2D

var origin := Vector2.ZERO
var travel := Vector2.ZERO
var period := 3.0
var phase := 0.0
var elapsed := 0.0

func setup(new_travel: Vector2, new_period: float, new_phase: float = 0.0) -> void:
	origin = global_position
	travel = new_travel
	period = maxf(new_period, 0.5)
	phase = new_phase

func _physics_process(delta: float) -> void:
	elapsed += delta
	var t := (sin((elapsed / period) * TAU + phase) + 1.0) * 0.5
	global_position = origin + travel * t
