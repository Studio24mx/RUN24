extends Area2D

@export var damage := 1
@export var contact_check_interval := 0.08

var contact_check_left := 0.0
var visual_time := 0.0

@onready var visual: Polygon2D = $Visual

func _ready() -> void:
	add_to_group("hazards")
	collision_layer = 0
	collision_mask = 2
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	visual_time += delta
	if is_instance_valid(visual):
		visual.scale.y = 1.0 + sin(visual_time * 5.5) * 0.055
		visual.modulate = Color(1.0, 0.82 + sin(visual_time * 4.0) * 0.08, 0.90, 1.0)
	# Re-check contact several times per second. take_damage() owns the player's
	# invulnerability window, so a player who remains on the spikes is damaged
	# again as soon as that window ends instead of becoming permanently safe.
	contact_check_left = maxf(contact_check_left - delta, 0.0)
	if contact_check_left > 0.0:
		return
	contact_check_left = contact_check_interval
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
