shader_type canvas_item;
render_mode unshaded;
// Discovery mask only: no TIME, vertex warp, swimming, glint or fake motion.
uniform vec4 silhouette_color : source_color = vec4(0.19, 0.31, 0.30, 0.76);
void fragment() {
	float alpha = texture(TEXTURE, UV).a;
	COLOR = vec4(silhouette_color.rgb, alpha * silhouette_color.a);
}
