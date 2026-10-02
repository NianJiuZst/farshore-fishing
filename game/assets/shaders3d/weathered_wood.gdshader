shader_type spatial;
uniform vec4 wood_color : source_color = vec4(0.40,0.29,0.17,1.0);
varying vec3 world_pos;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){
    vec2 p=world_pos.xz;
    float coarse=noise(vec2(p.x*0.9,p.y*39.0));
    float fibers=noise(vec2(p.x*4.0,p.y*170.0));
    float grain=smoothstep(0.36,0.70,coarse)*0.19+fibers*0.10;
    float weather=noise(p*2.8)*0.13;
    ALBEDO=wood_color.rgb*(0.79+grain+weather);
    ROUGHNESS=0.80+fibers*0.14;
}
