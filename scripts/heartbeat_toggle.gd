extends Node
## Switches every heart-beat zone in the scene between a regular and an irregular beat, and
## shows which on a label. Wired to a HexRPhysicalButton's "pressed" signal, and registered as
## a HexR Remote command so the phone can do it too.

@export var label: Label3D


func _ready() -> void:
	HexRRemote.register_command("toggle_heartbeat", "Toggle heartbeat", toggle)
	_show()


func _exit_tree() -> void:
	HexRRemote.unregister_command("toggle_heartbeat")


func toggle() -> void:
	for zone in get_tree().current_scene.find_children("*", "HexRSpecialHaptics", true, false):
		if zone.effect == HexRSpecialHaptics.Effect.HEART_BEAT:
			zone.toggle_heart_regularity()
	_show()


func _show() -> void:
	if label == null:
		return
	var irregular := false
	for zone in get_tree().current_scene.find_children("*", "HexRSpecialHaptics", true, false):
		if zone.effect == HexRSpecialHaptics.Effect.HEART_BEAT:
			irregular = zone.heart_beat == HexRSpecialHaptics.HeartBeat.IRREGULAR
	label.text = "Pulse: " + ("IRREGULAR" if irregular else "regular")
