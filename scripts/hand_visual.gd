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
	_add_palm_bone(skeleton[0])
	var modifier := XRHandModifier3D.new()
	modifier.hand_tracker = tracker
	skeleton[0].add_child(modifier)


## The demo mesh has no palm bone, and XRHandModifier3D warns about that each time XR starts or
## stops. An unskinned one, where the middle metacarpal is, keeps it quiet and changes nothing.
func _add_palm_bone(skeleton: Skeleton3D) -> void:
	var side := "Left" if left else "Right"
	if skeleton.find_bone(side + "Palm") >= 0:
		return
	var metacarpal := skeleton.find_bone(side + "MiddleMetacarpal")
	var palm := skeleton.add_bone(side + "Palm")
	skeleton.set_bone_parent(palm, skeleton.find_bone(side + "Hand"))
	skeleton.set_bone_rest(palm, skeleton.get_bone_rest(metacarpal))
	skeleton.reset_bone_pose(palm)
