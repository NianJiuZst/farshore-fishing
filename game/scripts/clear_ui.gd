class_name ClearUI
extends RefCounted
## Interaction geometry stays large; only the icon, text and focus outline draw.
const STATES: Array[String] = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]
const INK := Color("f5f2e9")
const MUTED := Color("d5e3d9")
const TEAL := Color("a5dfce")
const GOLD := Color("f1cf8c")
const OUTLINE := Color("10272e")
static func surface(focused: bool = false, margin: float = 0.0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.draw_center = false
	box.bg_color = Color.TRANSPARENT
	box.border_color = GOLD if focused else Color.TRANSPARENT
	box.set_border_width_all(2 if focused else 0)
	box.set_corner_radius_all(12)
	for side: int in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: box.set_content_margin(side,margin)
	return box
static func style_button(button: BaseButton) -> void:
	for state: String in STATES: button.add_theme_stylebox_override(state,surface(state == "focus"))
static func style_text(label: Label) -> void:
	label.add_theme_color_override("font_outline_color",OUTLINE)
	label.add_theme_color_override("font_shadow_color",Color(0.01,0.04,0.06,0.85))
	label.add_theme_constant_override("outline_size",3)
	label.add_theme_constant_override("shadow_offset_y",2)
