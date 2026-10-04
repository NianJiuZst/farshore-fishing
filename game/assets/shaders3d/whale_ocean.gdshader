shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform vec3 water_color : source_color = vec3(0.035, 0.32, 0.39);
uniform float wave_clock = 0.0;
varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float wave = sin(world_position.x * 0.22 + wave_clock * 0.8) * 0.06;
	wave += sin(world_position.z * 0.31 - wave_clock * 0.6) * 0.035;
	VERTEX.y += wave;
}

void fragment() {
	float crossing_waves = sin(world_position.x * 0.70 + sin(world_position.z * 0.18) * 2.0 + wave_clock * 0.7);
	crossing_waves *= sin(world_position.z * 0.80 + sin(world_position.x * 0.13) * 3.2 - wave_clock * 0.45);
	float crest = smoothstep(0.84, 1.0, crossing_waves);
	ALBEDO = mix(water_color, vec3(0.30, 0.70, 0.76), crest * 0.18);
	ROUGHNESS = 0.13;
	METALLIC = 0.14;
	SPECULAR = 0.70;
	ALPHA = 0.18 + crest * 0.04;
	NORMAL_MAP = vec3(0.5 + sin(world_position.x * 0.9 + wave_clock) * 0.10, 0.5 + cos(world_position.z * 1.2 - wave_clock) * 0.07, 1.0);
}
