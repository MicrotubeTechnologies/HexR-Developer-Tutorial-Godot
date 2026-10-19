extends XRNode3D
## A tracked hand you can see: the humanoid hand mesh from Godot's hand tracking demo, posed by
## XRHandModifier3D from the OpenXR hand tracker. HexR's touch points come from the same
## tracker (see HexRTrackedHand), so what you see and what you feel line up.

const LEFT_MESH := preload("res://assets/hands/LeftHandHumanoid.gltf")
const RIGHT_MESH := preload("res://assets/hands/RightHandHumanoid.gltf")

@export var left := true


func _ready() -> void:
	tracker = &"/user/hand_tracker/left" if left else &"/user/hand_tracker/right"
	show_when_tracked = true
	var mesh: Node3D = (LEFT_MESH if left else RIGHT_MESH).instantiate()
	add_child(mesh)
	var skeleton := mesh.find_children("*", "Skeleton3D", true, false)
	if skeleton.is_empty():
		push_warning("Hand mesh has no Skeleton3D")
		return
	var modifier := XRHandModifier3D.new()
	modifier.hand_tracker = tracker
	skeleton[0].add_child(modifier)
