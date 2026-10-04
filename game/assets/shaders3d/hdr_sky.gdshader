shader_type sky;
// Native environment lighting. Photographed terrain/horizon is deliberately excluded.
uniform sampler2D panorama : source_color, filter_linear_mipmap, repeat_enable;
uniform vec3 horizon_color : source_color = vec3(0.56,0.67,0.73);
uniform vec3 ground_color : source_color = vec3(0.10,0.15,0.13);
uniform float energy = 1.0;
uniform vec3 sky_tint : source_color = vec3(1.0);
uniform float cloud_saturation : hint_range(0.0, 1.0) = 1.0;
uniform float horizon_warmth : hint_range(0.0, 1.0) = 0.0;
void sky(){
    vec3 d=normalize(EYEDIR);
    vec2 uv=vec2(atan(d.x,d.z)/6.28318530718+0.5,acos(clamp(d.y,-1.0,1.0))/3.14159265359);
    vec3 hdr=texture(panorama,uv).rgb;
    float luminance=dot(hdr,vec3(0.2126,0.7152,0.0722));
    hdr=mix(vec3(luminance),hdr,cloud_saturation)*sky_tint;
    // Broad low-angle light warms cloud undersides while preserving HDR detail.
    float dusk_band=exp(-max(d.y,0.0)*5.5)*horizon_warmth;
    hdr=mix(hdr,hdr*vec3(1.18,0.82,0.62),dusk_band);
    vec3 horizon=mix(ground_color,horizon_color,smoothstep(-0.15,0.02,d.y));
    COLOR=mix(horizon,hdr,smoothstep(0.065,0.155,d.y))*energy;
}
