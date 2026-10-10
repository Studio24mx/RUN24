extends Node

var player: Node2D
var motes: CPUParticles2D
var ash: CPUParticles2D
var fog: CPUParticles2D

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_sky()
	_build_screen_grade()
	_build_world_particles()

func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var anchor := player.global_position + Vector2(180, -160)
	if is_instance_valid(motes):
		motes.global_position = anchor
	if is_instance_valid(ash):
		ash.global_position = anchor + Vector2(-80, 40)
	if is_instance_valid(fog):
		fog.global_position = player.global_position + Vector2(120, 115)

func _build_sky() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -20
	add_child(layer)
	var sky := ColorRect.new()
	sky.position = Vector2.ZERO
	sky.size = Vector2(1280, 720)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
void fragment() {
	vec2 uv = UV;
	vec3 top = vec3(0.012, 0.014, 0.026);
	vec3 horizon = vec3(0.055, 0.025, 0.052);
	vec3 bottom = vec3(0.010, 0.024, 0.030);
	float h = smoothstep(0.0, 0.72, uv.y);
	vec3 col = mix(top, horizon, h);
	col = mix(col, bottom, smoothstep(0.62, 1.0, uv.y));
	float ribbon_y = 0.20 + sin(uv.x * 5.4 + TIME * 0.10) * 0.035;
	float ribbon = exp(-pow((uv.y - ribbon_y) * 10.0, 2.0));
	col += vec3(0.18, 0.015, 0.060) * ribbon * 0.34;
	float signal_y = 0.34 + sin(uv.x * 8.0 - TIME * 0.07) * 0.018;
	float signal = exp(-pow((uv.y - signal_y) * 18.0, 2.0));
	col += vec3(0.020, 0.13, 0.12) * signal * 0.18;
	COLOR = vec4(col, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	sky.material = mat
	layer.add_child(sky)

func _build_screen_grade() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 18
	add_child(layer)

	var grade := ColorRect.new()
	grade.position = Vector2.ZERO
	grade.size = Vector2(1280, 720)
	grade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
void fragment() {
	vec2 uv = SCREEN_UV;
	vec4 c = texture(screen_texture, uv);
	float d = distance(uv, vec2(0.5));
	float vignette = smoothstep(0.33, 0.78, d);
	float scan = sin(uv.y * 720.0 * 3.14159265) * 0.004;
	float grain = fract(sin(dot(uv * vec2(1280.0, 720.0) + TIME * 11.0, vec2(12.9898, 78.233))) * 43758.5453);
	c.rgb *= 1.0 - vignette * 0.30;
	c.rgb = mix(c.rgb, pow(max(c.rgb, vec3(0.0)), vec3(0.88)), 0.18);
	c.rgb += (grain - 0.5) * 0.018 + scan;
	float red_push = smoothstep(0.55, 1.0, uv.x) * 0.012;
	c.r += red_push;
	COLOR = vec4(c.rgb, 1.0);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = shader
	grade.material = mat
	layer.add_child(grade)

	var top_haze := ColorRect.new()
	top_haze.position = Vector2(0, 54)
	top_haze.size = Vector2(1280, 150)
	top_haze.color = Color(0.08, 0.02, 0.07, 0.10)
	top_haze.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(top_haze)

func _build_world_particles() -> void:
	var mote_tex := _make_particle_texture(Color(0.20, 0.84, 0.78, 1.0), 16)
	var ash_tex := _make_particle_texture(Color(0.92, 0.86, 0.76, 1.0), 10)
	var fog_tex := _make_particle_texture(Color(0.22, 0.05, 0.11, 1.0), 24)

	motes = CPUParticles2D.new()
	motes.amount = 44
	motes.lifetime = 5.5
	motes.preprocess = 5.5
	motes.randomness = 0.75
	motes.texture = mote_tex
	motes.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	motes.emission_rect_extents = Vector2(730, 285)
	motes.direction = Vector2(-0.25, -1.0)
	motes.spread = 55.0
	motes.gravity = Vector2(-4, -10)
	motes.initial_velocity_min = 5.0
	motes.initial_velocity_max = 22.0
	motes.scale_amount_min = 0.16
	motes.scale_amount_max = 0.55
	motes.color = Color(0.20, 0.84, 0.78, 0.22)
	motes.local_coords = false
	motes.z_index = -1
	add_child(motes)

	ash = CPUParticles2D.new()
	ash.amount = 32
	ash.lifetime = 7.0
	ash.preprocess = 7.0
	ash.randomness = 0.9
	ash.texture = ash_tex
	ash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	ash.emission_rect_extents = Vector2(760, 300)
	ash.direction = Vector2(-0.15, 1.0)
	ash.spread = 70.0
	ash.gravity = Vector2(-6, 7)
	ash.initial_velocity_min = 3.0
	ash.initial_velocity_max = 14.0
	ash.scale_amount_min = 0.12
	ash.scale_amount_max = 0.42
	ash.color = Color(0.95, 0.90, 0.82, 0.16)
	ash.local_coords = false
	ash.z_index = 10
	add_child(ash)

	fog = CPUParticles2D.new()
	fog.amount = 14
	fog.lifetime = 6.5
	fog.preprocess = 6.5
	fog.randomness = 0.85
	fog.texture = fog_tex
	fog.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	fog.emission_rect_extents = Vector2(760, 75)
	fog.direction = Vector2(-1.0, -0.05)
	fog.spread = 18.0
	fog.gravity = Vector2(-12, 0)
	fog.initial_velocity_min = 8.0
	fog.initial_velocity_max = 28.0
	fog.scale_amount_min = 4.0
	fog.scale_amount_max = 9.0
	fog.color = Color(0.32, 0.035, 0.09, 0.045)
	fog.local_coords = false
	fog.z_index = -3
	add_child(fog)

func _make_particle_texture(base: Color, size: int) -> Texture2D:
	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size - 1, size - 1) * 0.5
	var radius := float(size) * 0.5
	for y in range(size):
		for x in range(size):
			var distance := Vector2(x, y).distance_to(center) / radius
			var alpha := clampf(1.0 - distance, 0.0, 1.0)
			alpha = alpha * alpha
			image.set_pixel(x, y, Color(base.r, base.g, base.b, alpha))
	return ImageTexture.create_from_image(image)
