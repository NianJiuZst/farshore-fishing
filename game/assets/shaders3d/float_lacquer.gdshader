shader_type spatial;
render_mode blend_mix, depth_prepass_alpha;

uniform vec4 paint_color : source_color = vec4(1.0);
uniform float paint_roughness : hint_range(0.0, 1.0) = 0.4;
uniform float paint_metallic : hint_range(0.0, 1.0) = 0.0;
uniform float lacquer_amount : hint_range(0.0, 1.0) = 0.0;
uniform bool at_water_surface = false;
uniform float water_height = 0.0;
varying float world_height;

void vertex() {
    world_height = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
    // Fine sight-tip markings lose contrast rapidly through reflective water.
    // All underwater geometry still exists; cast/landing use ordinary lacquer.
    float depth = at_water_surface ? max(0.0, water_height - world_height) : 0.0;
    float visibility = 1.0 - smoothstep(0.002, 0.030, depth);
    if (visibility <= 0.001) {
        discard;
    }
    ALBEDO = mix(paint_color.rgb, vec3(0.12, 0.25, 0.24), min(depth * 18.0, 0.52));
    ROUGHNESS = paint_roughness;
    METALLIC = paint_metallic;
    SPECULAR = 0.5;
    CLEARCOAT = lacquer_amount;
    CLEARCOAT_ROUGHNESS = 0.22;
    ALPHA = paint_color.a * visibility;
}
