shader_type spatial;
render_mode cull_back;
uniform vec4 leaf_color : source_color=vec4(0.17,0.29,0.13,1.0);
uniform float motion_time=0.0;
uniform float wind_strength=1.0;
varying float shade;
void vertex() {
    vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float sway=sin(world.x*0.31+motion_time*0.73)+sin(world.z*0.43+motion_time*1.08)*0.4;
    float weight=clamp((world.y-1.5)*0.12,0.0,1.0);
    VERTEX.x+=sway*weight*0.12*wind_strength;
    VERTEX.z+=cos(world.x*0.4+motion_time)*weight*0.04*wind_strength;
    shade=0.90+0.12*sin(world.x*1.31+world.z*1.71+world.y*1.22);
}
void fragment(){ALBEDO=leaf_color.rgb*shade;ROUGHNESS=0.91; BACKLIGHT=leaf_color.rgb*0.13;}
