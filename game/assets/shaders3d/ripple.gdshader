shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 ripple_color : source_color=vec4(0.57,0.71,0.61,0.35);
uniform float progress=0.0;
void vertex(){float angle=atan(VERTEX.z,VERTEX.x);float wobble=sin(angle*7.0+progress*2.0)*0.019+sin(angle*13.0-progress)*0.011;VERTEX.xz*=1.0+wobble;}
void fragment(){float crest=pow(max(sin(UV.y*3.14159265),0.0),1.7);float breakup=0.62+0.25*sin(UV.x*94.24+progress*2.0)+0.13*sin(UV.x*251.32-progress*4.0);ALBEDO=ripple_color.rgb;ALPHA=ripple_color.a*crest*clamp(breakup,0.2,1.0);}
