extends Node3D
## Without a headset (running on the PC) the scene still opens: a camera at head height and a
## note. Gloves can still be tested from HexR Tools' Haptics Tester in the editor.

@export var start_xr: Node


func _ready() -> void:
	if start_xr and start_xr.has_signal("xr_failed_to_initialize"):
		start_xr.xr_failed_to_initialize.connect(_desktop)


func _desktop() -> void:
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.6, 0.6)
	cam.rotation_degrees = Vector3(-18, 0, 0)
	add_child(cam)
	cam.make_current()
	var note := Label3D.new()
	note.text = "No headset found.\nExport to Quest or PICO to try the gloves in XR,\nor test them from HexR Tools in the editor (under the Inspector)."
	note.font_size = 28
	note.pixel_size = 0.0015
	note.position = Vector3(0, 1.45, -0.4)
	add_child(note)
