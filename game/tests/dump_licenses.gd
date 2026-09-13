extends SceneTree
func _initialize() -> void:
	var text: String = Engine.get_license_text() + "\n\nTHIRD-PARTY LICENSES\n\n"
	var licenses: Dictionary = Engine.get_license_info()
	for key: String in licenses: text += key + "\n" + str(licenses[key]) + "\n\n"
	text += "\nCOPYRIGHT NOTICES\n" + JSON.stringify(Engine.get_copyright_info(), "  ")
	var file: FileAccess = FileAccess.open("res://data/GODOT_LICENSE.txt", FileAccess.WRITE)
	file.store_string(text)
	file.close()
	quit()
