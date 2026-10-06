shader_type canvas_item;
render_mode unshaded;
uniform sampler2D scene_texture : hint_screen_texture, filter_linear_mipmap;
void fragment() {
    // Keep the actual landscape. Defocus detail behind reading pages, without
    // adding a colored panel, card or opaque paper sheet behind the controls.
    COLOR = textureLod(scene_texture, SCREEN_UV, 3.5);
}
