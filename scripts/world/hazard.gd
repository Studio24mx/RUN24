extends Area2D

@export var damage := 1

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _physics_process(_delta: float) -> void:
	# Keep attempting damage while the player remains on the spikes.
	# Player invulnerability controls the actual damage cadence.
	for body in get_overlapping_bodies():
		_damage_body(body)

func _on_body_entered(body: Node2D) -> void:
	_damage_body(body)

func _damage_body(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var horizontal := signf(body.global_position.x - global_position.x)
		if is_zero_approx(horizontal):
			horizontal = 1.0
		var push := Vector2(horizontal * 280.0, -420.0)
		body.take_damage(damage, push)
