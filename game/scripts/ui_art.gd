class_name ExpeditionArt
extends Control
# Production illustration renderer. Every visible icon is a generated RGBA asset;
# no primitive/vector placeholder or background plate is drawn at runtime.
const ICON_ROOT: String="res://assets/ui/icons/"
const REQUIRED_ICONS: Array[String]=[
	"rod","reel","hook","bag","compass","book","heart","coin","badge",
	"pause","settings","sound","back","arrow","sort","search","release",
	"worm","grain","shrimp","lure","sun","dusk","rain","ruler"
]
static var _textures: Dictionary={}
static var _reported: Dictionary={}
var kind: String="compass":
	set(value):
		if kind==value:return
		kind=value
		queue_redraw()
# Kept as compatibility fields for existing layout call sites. Illustrations retain
# their authored colors; these fields intentionally do not recolor the bitmap.
var accent: Color=Color.WHITE
var ink: Color=Color.WHITE
var progress: float=0.0
var ticks: int=20
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_LINEAR
	resized.connect(queue_redraw)
func _draw() -> void:
	if kind=="none" or size.x<=0 or size.y<=0:return
	var texture: Texture2D=texture_for(kind)
	if texture==null:return
	var source: Vector2=texture.get_size()
	var factor: float=minf(size.x/source.x,size.y/source.y)
	var extent: Vector2=source*factor
	draw_texture_rect(texture,Rect2((size-extent)*0.5,extent),false)
static func texture_for(icon_kind: String) -> Texture2D:
	if icon_kind=="none":return null
	if _textures.has(icon_kind):return _textures[icon_kind] as Texture2D
	var path: String=ICON_ROOT+icon_kind+".png"
	if icon_kind not in REQUIRED_ICONS or not ResourceLoader.exists(path):
		_report_missing(icon_kind)
		return null
	var texture: Texture2D=load(path) as Texture2D
	if texture==null:
		_report_missing(icon_kind)
		return null
	_textures[icon_kind]=texture
	return texture
static func validate_assets() -> Array[String]:
	var errors: Array[String]=[]
	for icon_kind: String in REQUIRED_ICONS:
		var texture: Texture2D=texture_for(icon_kind)
		if texture==null:
			errors.append("缺少高清界面图标："+icon_kind)
		elif texture.get_width()<512 or texture.get_height()<512:
			errors.append("界面图标低于 512×512："+icon_kind)
	return errors
static func _report_missing(icon_kind: String) -> void:
	if not _reported.has(icon_kind):
		_reported[icon_kind]=true
		push_error("Missing required generated UI icon: "+ICON_ROOT+icon_kind+".png")
