shader_type spatial;
uniform vec4 ground_color : source_color=vec4(0.27,0.34,0.18,1.0);
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){float n=noise(world_pos.xz*1.3)*0.55+noise(world_pos.xz*19.0)*0.22;ALBEDO=ground_color.rgb*(0.70+n);ROUGHNESS=0.97;}
