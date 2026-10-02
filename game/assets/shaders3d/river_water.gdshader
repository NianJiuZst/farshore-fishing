shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled;
uniform vec3 deep_color : source_color = vec3(0.026,0.112,0.118);
uniform vec3 shallow_color : source_color = vec3(0.10,0.26,0.21);
uniform vec3 foam_color : source_color = vec3(0.67,0.75,0.56);
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float motion_time = 0.0;
uniform float wind_strength = 1.0;
uniform vec4 impact_a = vec4(0.0,0.0,-100.0,0.0);
uniform vec4 impact_b = vec4(0.0,0.0,-100.0,0.0);
varying vec3 world_pos;
float wave(vec2 p, float t) {
    float warp=sin(p.x*0.47-p.y*0.29+t*0.22)*0.85+sin(p.y*0.71+p.x*0.12)*0.31;
    return sin(dot(p,vec2(0.87,0.38))*2.1+t*1.05+warp)*0.006 + sin(dot(p,vec2(-0.67,0.74))*3.7-t*1.43+warp*0.72)*0.004 + sin(dot(p,vec2(0.55,-0.81))*7.4+t*1.73+sin(p.x*1.7)*0.4)*0.002;
}
float impact(vec2 p, vec4 info) {
    float age=motion_time-info.z;
    float d=length(p-info.xy);
    float envelope=exp(-abs(d-age*1.25)*4.0)*max(0.0,1.0-age/4.0)*step(0.0,age);
    return sin((d-age*1.25)*15.0)*envelope*info.w;
}
void vertex() {
    world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    float h=wave(world_pos.xz,motion_time)*wind_strength;
    h+=impact(world_pos.xz,impact_a)+impact(world_pos.xz,impact_b);
    VERTEX.y+=h;
}
void fragment() {
    vec2 p=world_pos.xz;
    float e=0.035;
    float a=wave(p+vec2(e,0.0),motion_time)-wave(p-vec2(e,0.0),motion_time);
    float b=wave(p+vec2(0.0,e),motion_time)-wave(p-vec2(0.0,e),motion_time);
    a+=(impact(p+vec2(e,0),impact_a)-impact(p-vec2(e,0),impact_a))*0.7;
    b+=(impact(p+vec2(0,e),impact_a)-impact(p-vec2(0,e),impact_a))*0.7;
    vec3 micro_a=texture(normal_texture,p*0.15+vec2(motion_time*0.013,-motion_time*0.008)).rgb*2.0-1.0;
    vec3 micro_b=texture(normal_texture,p*0.41+vec2(-motion_time*0.009,motion_time*0.019)).rgb*2.0-1.0;
    vec2 micro=(micro_a.xy*0.75+micro_b.xy*0.25)*0.30;
    vec3 n=normalize(vec3((-a/(2.0*e)*0.5+micro.x)*wind_strength,1.0,(-b/(2.0*e)*0.5+micro.y)*wind_strength));
    NORMAL=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
    float fresnel=pow(1.0-clamp(dot(NORMAL,VIEW),0.0,1.0),4.0);
    float variation=sin(p.x*0.3+p.y*0.12)*0.5+0.5;
    vec3 base=mix(deep_color,shallow_color,variation*0.38);
    float rip=max(abs(impact(p,impact_a)),abs(impact(p,impact_b)));
    float shore=abs(abs(p.x)-(9.8+1.9*sin(p.y*0.065)+1.4*cos(p.y*0.14)));
    float shore_foam=(1.0-smoothstep(0.05,0.42,shore))*smoothstep(-0.2,0.9,sin(p.y*12.0+sin(p.x*6.0)+motion_time*0.7))*0.38;
    float foam=smoothstep(0.012,0.044,rip)*0.42+shore_foam;
    ALBEDO=mix(base,foam_color,foam);
    METALLIC=0.04;
    ROUGHNESS=mix(0.19,0.095,fresnel)+foam*0.25;
    SPECULAR=0.70;
    ALPHA=mix(0.76,0.97,fresnel);
}
