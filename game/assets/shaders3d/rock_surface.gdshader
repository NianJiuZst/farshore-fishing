shader_type spatial;
uniform vec4 rock_tint : source_color = vec4(0.82,0.87,0.92,1.0);
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
uniform float meters_per_tile=2.7;
varying vec3 world_pos;
varying vec3 world_normal;
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
    vec3 p=world_pos/meters_per_tile;
    vec3 w=pow(abs(world_normal),vec3(4.0));w/=max(w.x+w.y+w.z,0.001);
    vec3 c=texture(rock_albedo,p.zy).rgb*w.x+texture(rock_albedo,p.xz).rgb*w.y+texture(rock_albedo,p.xy).rgb*w.z;
    ALBEDO=c*rock_tint.rgb;
    ROUGHNESS=clamp(texture(rock_roughness,p.zy).r*w.x+texture(rock_roughness,p.xz).r*w.y+texture(rock_roughness,p.xy).r*w.z,0.55,0.98);
    vec3 a=texture(rock_normal,p.zy).rgb*2.0-1.0;
    vec3 b=texture(rock_normal,p.xz).rgb*2.0-1.0;
    vec3 cnormal=texture(rock_normal,p.xy).rgb*2.0-1.0;
    vec3 nx=vec3(max(a.z,0.1)*sign(world_normal.x),a.y*.46,a.x*.46);
    vec3 ny=vec3(b.x*.46,max(b.z,0.1)*sign(world_normal.y),b.y*.46);
    vec3 nz=vec3(cnormal.x*.46,cnormal.y*.46,max(cnormal.z,0.1)*sign(world_normal.z));
    vec3 n=normalize(nx*w.x+ny*w.y+nz*w.z);
    NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
}
