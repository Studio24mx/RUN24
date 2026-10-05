extends Area2D

@export var damage := 1

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		var push := Vector2(signf(body.global_position.x - global_position.x) * 280.0, -420.0)
		body.take_damage(damage, push)
