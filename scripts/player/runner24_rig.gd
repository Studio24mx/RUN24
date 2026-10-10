extends Node2D

const GHOST_TEXTURE := preload("res://art/game/characters/runner24/runtime/runner24_ghost.png")

@onready var body_flip: Node2D = $BodyFlip
@onready var pelvis_bone: Node2D = $BodyFlip/BodyRig/Root/PelvisBone
@onready var torso_bone: Node2D = $BodyFlip/BodyRig/Root/TorsoBone
@onready var head_bone: Node2D = $BodyFlip/BodyRig/Root/TorsoBone/HeadBone
@onready var arm_back_bone: Node2D = $BodyFlip/BodyRig/Root/TorsoBone/ArmBackBone
@onready var leg_back_bone: Node2D = $BodyFlip/BodyRig/Root/PelvisBone/LegBackBone
@onready var leg_front_bone: Node2D = $BodyFlip/BodyRig/Root/PelvisBone/LegFrontBone
@onready var scarf_back_bone: Node2D = $BodyFlip/BodyRig/Root/TorsoBone/ScarfBackBone
@onready var scarf_front_bone: Node2D = $BodyFlip/BodyRig/Root/TorsoBone/ScarfFrontBone
@onready var core_sprite: Sprite2D = $BodyFlip/BodyRig/Root/TorsoBone/Core
@onready var aim_pivot: Node2D = $AimPivot
@onready var aim_arm: Sprite2D = $AimPivot/ArmFront
@onready var weapon_sprite: Sprite2D = $AimPivot/Weapon

var land_kick := 0.0
var hurt_kick := 0.0
var last_grounded := true

func update_pose(
	visual_time: float,
	velocity: Vector2,
	grounded: bool,
	facing: float,
	aim_direction: Vector2,
	dash_left: float,
	phase_rush_left: float,
	recoil: float,
	dead: bool
) -> void:
	var step := sin(visual_time * 14.0)
	var breathe := sin(visual_time * 3.0)
	var speed_ratio := clampf(absf(velocity.x) / 440.0, 0.0, 1.0)
	land_kick = move_toward(land_kick, 0.0, 0.14)
	hurt_kick = move_toward(hurt_kick, 0.0, 0.10)

	body_flip.scale.x = absf(body_flip.scale.x) * (1.0 if facing >= 0.0 else -1.0)

	if dead:
		rotation = lerpf(rotation, 1.15 * facing, 0.12)
		position.y = lerpf(position.y, 18.0, 0.12)
		modulate = modulate.lerp(Color(0.72, 0.18, 0.28, 0.75), 0.10)
	else:
		rotation = lerpf(rotation, 0.0, 0.20)
		position.y = lerpf(position.y, 0.0, 0.20)
		modulate = modulate.lerp(Color.WHITE, 0.15)

	var dash_pose := phase_rush_left > 0.0 or dash_left > 0.0
	if dash_pose:
		var phase_mult := 1.0 if phase_rush_left > 0.0 else 0.65
		torso_bone.rotation = lerpf(torso_bone.rotation, -0.14 * facing, 0.35)
		head_bone.rotation = lerpf(head_bone.rotation, 0.08 * facing, 0.30)
		pelvis_bone.rotation = lerpf(pelvis_bone.rotation, -0.10 * facing, 0.30)
		leg_front_bone.rotation = lerpf(leg_front_bone.rotation, -0.24 * facing, 0.35)
		leg_back_bone.rotation = lerpf(leg_back_bone.rotation, 0.20 * facing, 0.35)
		arm_back_bone.rotation = lerpf(arm_back_bone.rotation, 0.18 * facing, 0.35)
		scarf_back_bone.rotation = lerpf(scarf_back_bone.rotation, -0.42 * facing * phase_mult, 0.30)
		scarf_front_bone.rotation = lerpf(scarf_front_bone.rotation, -0.26 * facing, 0.30)
	elif not grounded:
		var rising := velocity.y < 0.0
		torso_bone.rotation = lerpf(torso_bone.rotation, (0.055 if rising else -0.045) * facing, 0.22)
		head_bone.rotation = lerpf(head_bone.rotation, (-0.035 if rising else 0.045) * facing, 0.22)
		pelvis_bone.rotation = lerpf(pelvis_bone.rotation, (-0.05 if rising else 0.04) * facing, 0.22)
		leg_front_bone.rotation = lerpf(leg_front_bone.rotation, (-0.24 if rising else 0.20) * facing, 0.26)
		leg_back_bone.rotation = lerpf(leg_back_bone.rotation, (0.28 if rising else -0.16) * facing, 0.26)
		arm_back_bone.rotation = lerpf(arm_back_bone.rotation, -0.12 * facing, 0.25)
	else:
		var run_amp := speed_ratio
		torso_bone.rotation = lerpf(torso_bone.rotation, (-0.045 * facing * run_amp) + breathe * 0.006, 0.24)
		head_bone.rotation = lerpf(head_bone.rotation, step * 0.015 * run_amp - torso_bone.rotation * 0.35, 0.24)
		pelvis_bone.rotation = lerpf(pelvis_bone.rotation, step * 0.018 * run_amp, 0.24)
		leg_front_bone.rotation = lerpf(leg_front_bone.rotation, step * 0.34 * run_amp, 0.34)
		leg_back_bone.rotation = lerpf(leg_back_bone.rotation, -step * 0.34 * run_amp, 0.34)
		arm_back_bone.rotation = lerpf(arm_back_bone.rotation, -step * 0.22 * run_amp, 0.30)
		scarf_back_bone.rotation = lerpf(scarf_back_bone.rotation, -0.10 * facing - velocity.x / 1900.0 + sin(visual_time * 5.0) * 0.035, 0.20)
		scarf_front_bone.rotation = lerpf(scarf_front_bone.rotation, -0.05 * facing - velocity.x / 2600.0 + sin(visual_time * 5.7) * 0.025, 0.20)

	var squash := 1.0 - land_kick * 0.12
	body_flip.scale.y = lerpf(body_flip.scale.y, squash, 0.28)

	var safe_aim := aim_direction.normalized() if aim_direction.length_squared() > 0.001 else Vector2(facing, 0)
	aim_pivot.position = Vector2(25.0 * facing, -94.0) - safe_aim * recoil * 7.0
	aim_pivot.rotation = safe_aim.angle()
	aim_arm.flip_v = safe_aim.x < 0.0
	weapon_sprite.flip_v = safe_aim.x < 0.0
	weapon_sprite.modulate = Color(1.0, 0.92 + recoil * 0.08, 0.80 + recoil * 0.20, 1.0)

	var core_pulse := 1.0 + sin(visual_time * 5.2) * 0.08 + recoil * 0.10
	core_sprite.scale = Vector2.ONE * core_pulse
	core_sprite.modulate = Color(1.0, 1.0, 1.0, 0.88 + sin(visual_time * 5.2) * 0.10)

func trigger_land() -> void:
	land_kick = 1.0

func trigger_hurt() -> void:
	hurt_kick = 1.0

func trigger_shoot() -> void:
	var tween := create_tween()
	tween.tween_property(core_sprite, "rotation", core_sprite.rotation + 0.22, 0.08)

func spawn_afterimage(parent: Node, world_position: Vector2, facing: float, phase: bool) -> void:
	var ghost := Sprite2D.new()
	ghost.texture = GHOST_TEXTURE
	ghost.centered = true
	ghost.z_index = 5
	ghost.global_position = world_position + Vector2(0, -41)
	ghost.scale = Vector2(0.55 * facing, 0.55)
	ghost.modulate = Color(1.0, 0.32, 0.68, 0.30) if phase else Color(0.20, 0.84, 0.78, 0.22)
	parent.add_child(ghost)
	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.tween_property(ghost, "scale", ghost.scale * Vector2(1.08, 0.94), 0.18)
	tween.chain().tween_callback(ghost.queue_free)
