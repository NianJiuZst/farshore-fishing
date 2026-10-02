shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 ripple_color : source_color=vec4(0.72,0.81,0.69,0.62);
void fragment(){ALBEDO=ripple_color.rgb;ALPHA=ripple_color.a;}
