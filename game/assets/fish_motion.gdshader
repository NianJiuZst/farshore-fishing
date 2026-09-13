shader_type canvas_item;
uniform bool silhouette = false;
uniform float amplitude = 0.006;
void fragment() {
	vec2 uv = UV;
	float tail = smoothstep(0.36, 0.94, uv.x);
	uv.y += sin(TIME * 1.9 + uv.x * 7.0) * amplitude * tail;
	vec4 tex = texture(TEXTURE, uv);
	COLOR = silhouette ? vec4(vec3(0.20,0.28,0.25), tex.a * 0.72) : tex * COLOR;
}
