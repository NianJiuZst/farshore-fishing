shader_type spatial;
render_mode cull_back;
uniform vec4 leaf_color : source_color=vec4(0.17,0.29,0.13,1.0);
uniform float motion_time=0.0;
uniform float wind_strength=1.0;
uniform bool clear_rock_station=false;
varying float shade;
varying vec3 leaf_world;
float hash(vec3 p){return fract(sin(dot(p,vec3(127.1,311.7,74.7)))*43758.5453);}
float noise(vec3 p){vec3 i=floor(p);vec3 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(mix(hash(i),hash(i+vec3(1,0,0)),f.x),mix(hash(i+vec3(0,1,0)),hash(i+vec3(1,1,0)),f.x),f.y),mix(mix(hash(i+vec3(0,0,1)),hash(i+vec3(1,0,1)),f.x),mix(hash(i+vec3(0,1,1)),hash(i+vec3(1,1,1)),f.x),f.y),f.z);}
void vertex() {
    vec3 world=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
    leaf_world=world;
    float sway=sin(world.x*0.31+motion_time*0.73)+sin(world.z*0.43+motion_time*1.08)*0.4;
    float weight=clamp((world.y-1.5)*0.12,0.0,1.0);
    VERTEX.x+=sway*weight*0.12*wind_strength;
    VERTEX.z+=cos(world.x*0.4+motion_time)*weight*0.04*wind_strength;
    shade=0.90+0.12*sin(world.x*1.31+world.z*1.71+world.y*1.22);
}
void fragment(){
    // Rock-bank cameras sit beneath authored trees. Prune only the near station's
    // canopy corridor; the fixed clearing never moves with a float or encounter.
    if(clear_rock_station && length(leaf_world.xz-vec2(-0.3,3.0))<7.0){discard;}
    float distance_fade=1.0-smoothstep(10.0,42.0,length(leaf_world-CAMERA_POSITION_WORLD));
    float fleck=mix(0.5,noise(leaf_world*18.0),distance_fade);
    float clump=noise(leaf_world*0.85);
    // Broad crown shading survives phone-size pixels; fine mottling fades into distance.
    ALBEDO=leaf_color.rgb*shade*(0.77+0.21*clump+0.10*fleck);
    ROUGHNESS=0.85;
    SPECULAR=0.20;
    BACKLIGHT=leaf_color.rgb*0.34;
}
