shader_type sky;
// Native environment lighting. Photographed terrain/horizon is deliberately excluded.
uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 horizon_color : source_color = vec3(0.56,0.67,0.73);
uniform vec3 ground_color : source_color = vec3(0.10,0.15,0.13);
uniform float energy = 1.0;
void sky(){
    vec3 d=normalize(EYEDIR);
    vec2 uv=vec2(atan(d.x,d.z)/6.28318530718+0.5,acos(clamp(d.y,-1.0,1.0))/3.14159265359);
    vec3 hdr=texture(panorama,uv).rgb;
    vec3 horizon=mix(ground_color,horizon_color,smoothstep(-0.15,0.02,d.y));
    COLOR=mix(horizon,hdr,smoothstep(0.065,0.155,d.y))*energy;
}
