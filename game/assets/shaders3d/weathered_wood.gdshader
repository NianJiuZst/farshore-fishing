shader_type spatial;
uniform vec4 wood_color : source_color = vec4(0.40,0.29,0.17,1.0);
uniform bool use_pbr = false;
uniform bool vertical_timber = false;
uniform float paint_strength = 0.0;
uniform sampler2D timber_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D timber_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D timber_roughness : filter_linear_mipmap_anisotropic, repeat_enable;
varying vec3 world_pos;
varying vec3 world_normal;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
float noise(vec2 p){vec2 i=floor(p);vec2 f=fract(p);f=f*f*(3.0-2.0*f);return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);}
void vertex(){world_pos=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);}
void fragment(){
    vec2 p=world_pos.xz;
    float coarse=noise(vec2(p.x*0.9,p.y*39.0));
    float fibers=noise(vec2(p.x*4.0,p.y*170.0));
    float grain=smoothstep(0.36,0.70,coarse)*0.19+fibers*0.10;
    float weather=noise(p*2.8)*0.13;
    ALBEDO=wood_color.rgb*(0.79+grain+weather);
    ROUGHNESS=0.80+fibers*0.14;
    if(use_pbr){
        // Eight scanned planks per 1.88m matches the actual authored 0.235m plank pitch.
        vec2 uv=vec2((p.y+1.6175)/1.88,p.x/2.8);
        if(vertical_timber){uv=vec2(abs(world_normal.z)>abs(world_normal.x)?world_pos.x/1.8:world_pos.z/1.8,world_pos.y/3.0);}
        vec3 timber=texture(timber_albedo,uv).rgb;
        ALBEDO=timber*mix(vec3(1.0),wood_color.rgb*2.8,0.22);
        ALBEDO=mix(ALBEDO,wood_color.rgb*(0.65+dot(timber,vec3(0.333))*0.75),paint_strength);
        ROUGHNESS=clamp(texture(timber_roughness,uv).r,0.50,0.98);
        vec3 detail=texture(timber_normal,uv).rgb*2.0-1.0;
        vec3 n=normalize(vec3(detail.y*0.45,max(detail.z,0.1),detail.x*0.45));
        vec3 detail_view=normalize((VIEW_MATRIX*vec4(n,0.0)).xyz);
        NORMAL=normalize(mix(NORMAL,detail_view,smoothstep(0.65,0.94,world_normal.y)));
        if(vertical_timber){vec3 vn=abs(world_normal.z)>abs(world_normal.x)?vec3(detail.x*0.4,detail.y*0.4,max(detail.z,0.1)*sign(world_normal.z)):vec3(max(detail.z,0.1)*sign(world_normal.x),detail.y*0.4,detail.x*0.4);NORMAL=normalize((VIEW_MATRIX*vec4(normalize(vn),0.0)).xyz);}
    }
}
