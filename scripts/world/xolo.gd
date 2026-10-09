extends Node2D

var player: Node2D
var hover_time := 0.0
var follow_velocity := Vector2.ZERO
var last_facing := 1.0

func _ready() -> void:
	z_index = 4

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
	var pulse := 1.0 + sin(hover_time * 4.0) * 0.025
	scale.y = lerpf(scale.y, pulse, 0.12)
