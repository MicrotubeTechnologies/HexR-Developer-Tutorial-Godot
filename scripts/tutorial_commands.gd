extends Node
## HexR Remote commands for the tutorial scenes: a phone running the HexR Companion lists
## these and can run them.

## Objects put back where they started by "reset".
@export var resettable: Array[NodePath] = []

var _starts: Dictionary = {}


func _ready() -> void:
	for path in resettable:
		var n := get_node_or_null(path) as Node3D
		if n:
			_starts[n] = n.global_transform
	HexRRemote.register_command("reset", "Reset the props", reset_props)


func _exit_tree() -> void:
	HexRRemote.unregister_command("reset")


func reset_props() -> void:
	for n: Node3D in _starts:
		if not is_instance_valid(n):
			continue
		n.global_transform = _starts[n]
		if n is RigidBody3D:
			(n as RigidBody3D).linear_velocity = Vector3.ZERO
			(n as RigidBody3D).angular_velocity = Vector3.ZERO
	var hub := HexRManager.get_instance()
	if hub:
		hub.left_hand.release_all_channels()
		hub.right_hand.release_all_channels()
