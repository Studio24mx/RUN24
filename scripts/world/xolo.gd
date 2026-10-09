extends Node2D

const FX_BURST_SCENE := preload("res://scenes/fx/burst.tscn")

var player: Node2D
var hover_time := 0.0
var follow_velocity := Vector2.ZERO
var last_facing := 1.0
var trail_left := 0.0

@onready var authored_sprite: Sprite2D = $AuthoredSprite

func _ready() -> void:
	z_index = 4

func _process(delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		if not is_instance_valid(player):
			return

	hover_time += delta
	trail_left = maxf(trail_left - delta, 0.0)
	last_facing = player.facing
	var behind := -last_facing * 78.0
	var target := player.global_position + Vector2(behind, -20.0 + sin(hover_time * 3.2) * 6.0)
	var distance := global_position.distance_to(target)

	if distance > 360.0:
		global_position = target
		follow_velocity = Vector2.ZERO
	else:
		var stiffness := 18.0
		var damping := 7.5
		var acceleration := (target - global_position) * stiffness - follow_velocity * damping
		follow_velocity += acceleration * delta
		global_position += follow_velocity * delta

	var speed_ratio := clampf(follow_velocity.length() / 420.0, 0.0, 1.0)
	var run_step := sin(hover_time * (8.0 + speed_ratio * 6.0))
	scale.x = absf(scale.x) * (-1.0 if last_facing < 0.0 else 1.0)
	scale.y = lerpf(scale.y, 1.0 + run_step * 0.022, 0.16)
	rotation = lerpf(rotation, clampf(follow_velocity.x / 1200.0, -0.08, 0.08), 0.14)
	authored_sprite.position.y = -4.0 + absf(run_step) * 1.8
	authored_sprite.modulate.a = 0.88 + (sin(hover_time * 4.5) + 1.0) * 0.055

	if speed_ratio > 0.38 and trail_left <= 0.0:
		trail_left = 0.20
		var fx = FX_BURST_SCENE.instantiate()
		get_tree().current_scene.add_child(fx)
		fx.global_position = global_position + Vector2(-last_facing * 28.0, 4.0)
		fx.setup(Color(0.20, 0.84, 0.78), 12.0, 0.16, 5)
