shader_type spatial;
uniform vec4 reed_color : source_color=vec4(0.28,0.32,0.12,1.0);
uniform bool clear_rock_station=false;
uniform float motion_time=0.0;
uniform float wind_strength=1.0;
varying vec3 world_pos;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;float bend=max(0.0,world_pos.y)*0.025*sin(motion_time*1.1+world_pos.x*2.0+world_pos.z);VERTEX.x+=bend*wind_strength;}
void fragment(){if(clear_rock_station&&abs(world_pos.x)<3.0&&world_pos.z>-2.5&&world_pos.z<6.5){discard;}ALBEDO=reed_color.rgb;ROUGHNESS=0.9;}
