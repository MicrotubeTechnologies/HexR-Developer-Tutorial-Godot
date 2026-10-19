extends SceneTree
## Builds the tutorial's scenes from code, so the layout and the HexR wiring live in one
## readable file. The output is ordinary .tscn files: open and change them in the editor freely
## (re-running this overwrites them).
##
##   godot --headless --path . -s res://tools/build_scenes.gd

const ORANGE := Color("#f2661a")
const SCENES: Array[String] = [
	"res://scenes/1_basic_tutorial.tscn",
	"res://scenes/2_hospital_tutorial.tscn",
	"res://scenes/3_water_effects.tscn",
]
const FONT := "res://addons/hexr/ui/fonts/Inter-Medium.ttf"
const FONT_BOLD := "res://addons/hexr/ui/fonts/Archivo-Bold.ttf"

var _root: Node


func _initialize() -> void:
	_save(_player_rig(), "res://common/player_rig.tscn")
	_save(_environment(), "res://common/environment.tscn")
	_save(_basic(), SCENES[0])
	_save(_hospital(), SCENES[1])
	_save(_water(), SCENES[2])
	quit()


# -- helpers --------------------------------------------------------------------------------

func _save(root: Node, path: String) -> void:
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed for %s: %d" % [path, err])
	err = ResourceSaver.save(ps, path)
	print("saved %s (%s)" % [path, error_string(err)])
	root.free()


func _begin(root: Node, root_name: String) -> Node:
	root.name = root_name
	_root = root
	return root


func _add(parent: Node, child: Node, child_name: String = "") -> Node:
	if not child_name.is_empty():
		child.name = child_name
	parent.add_child(child)
	child.owner = _root
	return child


func _instance(parent: Node, path: String, child_name: String = "") -> Node:
	var n: Node = load(path).instantiate()
	return _add(parent, n, child_name)


func _mat(color: Color, metallic: float = 0.0, roughness: float = 0.7, emission: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.metallic = metallic
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	if color.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m


func _mesh(parent: Node, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO, mesh_name: String = "Mesh") -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	return _add(parent, mi, mesh_name)


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _sphere(r: float) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	return s


func _cyl(r: float, h: float) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = r
	c.bottom_radius = r
	c.height = h
	return c


func _shape(parent: Node, shape: Shape3D, pos: Vector3 = Vector3.ZERO, shape_name: String = "Shape") -> CollisionShape3D:
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = pos
	return _add(parent, cs, shape_name)


func _box_shape(size: Vector3) -> BoxShape3D:
	var b := BoxShape3D.new()
	b.size = size
	return b


func _sphere_shape(r: float) -> SphereShape3D:
	var s := SphereShape3D.new()
	s.radius = r
	return s


func _cyl_shape(r: float, h: float) -> CylinderShape3D:
	var c := CylinderShape3D.new()
	c.radius = r
	c.height = h
	return c


## A small dark sign with a title and a few lines, like the Unity tutorial's info cards.
func _sign(parent: Node, pos: Vector3, yaw_deg: float, title: String, body: String, width: float = 0.32) -> Node3D:
	var sign := Node3D.new()
	sign.position = pos
	sign.rotation_degrees = Vector3(-12, yaw_deg, 0)
	_add(parent, sign, "Sign" + title.to_pascal_case().left(24))
	var lines := body.count("\n") + 1
	var height := 0.07 + 0.026 * lines
	_mesh(sign, _box(Vector3(width, height, 0.008)), _mat(Color(0.035, 0.04, 0.055)), Vector3(0, -height * 0.5 + 0.03, -0.006), "Panel")
	_mesh(sign, _box(Vector3(width, 0.006, 0.01)), _mat(ORANGE, 0.0, 0.5, 1.0), Vector3(0, 0.033, -0.004), "Accent")
	var t := Label3D.new()
	t.text = title
	t.font = load(FONT_BOLD)
	t.font_size = 36
	t.pixel_size = 0.0006
	t.position = Vector3(0, 0.012, 0.0)
	t.modulate = Color.WHITE
	_add(sign, t, "Title")
	var b := Label3D.new()
	b.text = body
	b.font = load(FONT)
	b.font_size = 22
	b.pixel_size = 0.0006
	b.width = (width - 0.03) / 0.0006
	b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	b.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	b.position = Vector3(0, -0.008, 0.0)
	b.modulate = Color(1, 1, 1, 0.8)
	_add(sign, b, "Body")
	return sign


func _table(parent: Node, pos: Vector3, size: Vector3 = Vector3(1.6, 0.04, 0.6), table_name: String = "Table") -> StaticBody3D:
	var t := StaticBody3D.new()
	t.position = pos
	_add(parent, t, table_name)
	var top_y := 0.78
	_mesh(t, _box(size), _mat(Color(0.22, 0.23, 0.26), 0.0, 0.6), Vector3(0, top_y, 0), "Top")
	_shape(t, _box_shape(size), Vector3(0, top_y, 0), "TopShape")
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_mesh(t, _box(Vector3(0.04, top_y, 0.04)), _mat(Color(0.12, 0.12, 0.14)),
					Vector3(sx * (size.x * 0.5 - 0.05), top_y * 0.5, sz * (size.z * 0.5 - 0.05)), "Leg%d%d" % [sx + 1, sz + 1])
	return t


## A rigid prop you can pick up with the glove: HexRGrabbable on a RigidBody3D.
func _grabbable_body(parent: Node, body_name: String, pos: Vector3, shape: Shape3D, grab_type: int, strength: float, grab_size: Vector3) -> RigidBody3D:
	var body := RigidBody3D.new()
	body.position = pos
	body.mass = 0.2
	_add(parent, body, body_name)
	_shape(body, shape)
	var grab := HexRGrabbable.new()
	grab.grab_type = grab_type
	grab.haptic_strength = strength
	_add(body, grab, "HexRGrabbable")
	_shape(grab, _box_shape(grab_size))
	return body


func _zone(parent: Node, zone_name: String, effect: int, pos: Vector3, shape: Shape3D) -> HexRSpecialHaptics:
	var z := HexRSpecialHaptics.new()
	z.effect = effect
	z.position = pos
	_add(parent, z, zone_name)
	_shape(z, shape)
	return z


func _particles(parent: Node, particles_name: String, pos: Vector3, amount: int, lifetime: float, direction: Vector3,
		spread: float, velocity: Vector2, gravity: Vector3, color: Color, size: float, box: Vector3 = Vector3.ZERO) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.position = pos
	p.amount = amount
	p.lifetime = lifetime
	var pm := ParticleProcessMaterial.new()
	pm.direction = direction
	pm.spread = spread
	pm.initial_velocity_min = velocity.x
	pm.initial_velocity_max = velocity.y
	pm.gravity = gravity
	if box != Vector3.ZERO:
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.emission_box_extents = box
	p.process_material = pm
	var drop := _sphere(size)
	drop.radial_segments = 6
	drop.rings = 3
	var m := _mat(color, 0.0, 0.2, 0.6)
	drop.material = m
	p.draw_pass_1 = drop
	return _add(parent, p, particles_name)


func _common(root: Node3D, title: String, subtitle: String) -> void:
	_instance(root, "res://common/environment.tscn", "Environment")
	_instance(root, "res://common/player_rig.tscn", "PlayerRig")
	var heading := Label3D.new()
	heading.text = title
	heading.font = load(FONT_BOLD)
	heading.font_size = 64
	heading.pixel_size = 0.0012
	heading.position = Vector3(0, 2.1, -1.6)
	_add(root, heading, "Heading")
	var sub := Label3D.new()
	sub.text = subtitle
	sub.font = load(FONT)
	sub.font_size = 30
	sub.pixel_size = 0.0012
	sub.modulate = Color(1, 1, 1, 0.7)
	sub.position = Vector3(0, 1.98, -1.6)
	_add(root, sub, "Subheading")


# -- shared parts ---------------------------------------------------------------------------

func _player_rig() -> Node:
	var origin := XROrigin3D.new()
	_begin(origin, "PlayerRig")
	var start := _instance(origin, "res://addons/godot-xr-tools/xr/start_xr.tscn", "StartXR")
	var cam := XRCamera3D.new()
	cam.position = Vector3(0, 1.6, 0)
	_add(origin, cam, "XRCamera3D")
	for left in [true, false]:
		var side := "Left" if left else "Right"
		var hand := XRNode3D.new()
		hand.set_script(load("res://scripts/hand_visual.gd"))
		hand.set("left", left)
		_add(origin, hand, side + "HandVisual")
		var controller := XRController3D.new()
		controller.tracker = &"left_hand" if left else &"right_hand"
		controller.pose = &"grip"
		_add(origin, controller, side + "Controller")
		_instance(controller, "res://addons/godot-xr-tools/functions/function_pickup.tscn", "FunctionPickup")
	# Both tracked hands, both Pressure Controllers: the whole HexR rig.
	_add(origin, HexRRig.new(), "HexRRig")
	var menu := HexRFloatingMenu.new()
	menu.position = Vector3(-0.62, 1.22, -0.42)
	menu.rotation_degrees = Vector3(0, 40, 0)
	menu.scenes = PackedStringArray(SCENES)
	_add(origin, menu, "HexRFloatingMenu")
	var remote := HexRRemote.new()
	remote.expose_scenes = true
	remote.scenes = SCENES
	_add(origin, remote, "HexRRemote")
	var notice := Node3D.new()
	notice.set_script(load("res://scripts/desktop_notice.gd"))
	notice.set("start_xr", start)
	_add(origin, notice, "DesktopNotice")
	return origin


func _environment() -> Node:
	var root := Node3D.new()
	_begin(root, "Environment")
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.16, 0.2, 0.3)
	sky_mat.sky_horizon_color = Color(0.5, 0.52, 0.58)
	sky_mat.ground_bottom_color = Color(0.08, 0.08, 0.09)
	sky_mat.ground_horizon_color = Color(0.4, 0.41, 0.45)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	_add(root, we, "WorldEnvironment")
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	_add(root, sun, "Sun")
	var floor_body := StaticBody3D.new()
	_add(root, floor_body, "Floor")
	var plane := PlaneMesh.new()
	plane.size = Vector2(12, 12)
	_mesh(floor_body, plane, _mat(Color(0.3, 0.31, 0.33), 0.0, 0.9), Vector3.ZERO, "Mesh")
	_shape(floor_body, _box_shape(Vector3(12, 0.1, 12)), Vector3(0, -0.05, 0))
	# A ring on the floor where to stand.
	var torus := TorusMesh.new()
	torus.inner_radius = 0.28
	torus.outer_radius = 0.3
	_mesh(root, torus, _mat(ORANGE, 0.0, 0.5, 0.8), Vector3(0, 0.005, 0), "StandHere")
	return root


# -- 1. Basic tutorial ----------------------------------------------------------------------

func _basic() -> Node:
	var root := Node3D.new()
	_begin(root, "BasicTutorial")
	_common(root, "1 · Basic Tutorial", "Grab, pinch, burn, press. Look at the menu on your left to connect the gloves.")
	var table := _table(root, Vector3(0, 0, -0.55))
	var top := 0.8

	var foam := _grabbable_body(table, "Foam", Vector3(-0.55, top + 0.05, 0.02), _box_shape(Vector3(0.09, 0.09, 0.09)),
			HexRGrabbable.GrabType.PALM, 20.0, Vector3(0.13, 0.13, 0.13))
	_mesh(foam, _box(Vector3(0.09, 0.09, 0.09)), _mat(Color(0.98, 0.85, 0.35), 0.0, 1.0))
	_sign(table, Vector3(-0.55, top + 0.22, -0.2), 0, "Foam",
			"Grab it with your whole hand.\nHexRGrabbable, palm grab, strength 20: soft.")

	var key := _grabbable_body(table, "Key", Vector3(-0.2, top + 0.02, 0.02), _box_shape(Vector3(0.09, 0.012, 0.03)),
			HexRGrabbable.GrabType.PINCH, 40.0, Vector3(0.11, 0.05, 0.06))
	_mesh(key, _box(Vector3(0.06, 0.006, 0.012)), _mat(Color(0.85, 0.68, 0.25), 0.9, 0.3), Vector3(0.02, 0, 0), "Shaft")
	_mesh(key, _cyl(0.016, 0.006), _mat(Color(0.85, 0.68, 0.25), 0.9, 0.3), Vector3(-0.025, 0, 0), "Bow")
	_sign(table, Vector3(-0.2, top + 0.22, -0.2), 0, "Key",
			"Pinch it between thumb and a finger.\nHexRGrabbable, pinch grab, strength 40.")

	var torch := _grabbable_body(table, "Torch", Vector3(0.15, top + 0.035, 0.02), _cyl_shape(0.02, 0.22),
			HexRGrabbable.GrabType.PALM, 30.0, Vector3(0.08, 0.26, 0.08))
	torch.rotation_degrees = Vector3(0, 0, 90)
	_mesh(torch, _cyl(0.018, 0.22), _mat(Color(0.35, 0.22, 0.12), 0.0, 0.9), Vector3.ZERO, "Handle")
	_mesh(torch, _cyl(0.028, 0.04), _mat(Color(0.15, 0.15, 0.16), 0.6, 0.4), Vector3(0, 0.12, 0), "Head")
	var flame_light := OmniLight3D.new()
	flame_light.set_script(load("res://scripts/flame.gd"))
	flame_light.light_color = Color(1.0, 0.6, 0.25)
	flame_light.omni_range = 0.8
	flame_light.position = Vector3(0, 0.18, 0)
	_add(torch, flame_light, "FlameLight")
	_particles(torch, "Flame", Vector3(0, 0.15, 0), 40, 0.5, Vector3.UP, 15, Vector2(0.1, 0.25), Vector3(0, 0.3, 0),
			Color(1.0, 0.55, 0.15), 0.008)
	var flame_zone := _zone(torch, "FlameZone", HexRSpecialHaptics.Effect.CUSTOM_VIBRATIONS, Vector3(0, 0.19, 0), _sphere_shape(0.05))
	flame_zone.vibration_frequency = 25.0
	flame_zone.haptic_strength = 0.6
	_sign(table, Vector3(0.15, top + 0.22, -0.2), 0, "Torch",
			"Pick it up, then put a fingertip in the flame.\nHexRGrabbable + HexRSpecialHaptics (custom vibrations, 25 Hz).")

	var button_base := StaticBody3D.new()
	button_base.position = Vector3(0.5, top + 0.015, 0.02)
	_add(table, button_base, "Button")
	_mesh(button_base, _cyl(0.04, 0.03), _mat(Color(0.2, 0.2, 0.22)), Vector3.ZERO, "Base")
	_shape(button_base, _cyl_shape(0.04, 0.03))
	var cap := _mesh(button_base, _cyl(0.028, 0.016), _mat(ORANGE, 0.0, 0.4, 0.4), Vector3(0, 0.022, 0), "Cap")
	var press := HexRPhysicalButton.new()
	press.cap = cap
	press.position = Vector3(0, 0.03, 0)
	_add(button_base, press, "HexRPhysicalButton")
	_shape(press, _cyl_shape(0.028, 0.02))
	var bulb := MeshInstance3D.new()
	bulb.mesh = _sphere(0.035)
	bulb.set_script(load("res://scripts/lightbulb.gd"))
	bulb.position = Vector3(0.62, top + 0.12, -0.05)
	_add(table, bulb, "Lightbulb")
	press.pressed.connect(Callable(bulb, "toggle"), CONNECT_PERSIST)
	_sign(table, Vector3(0.55, top + 0.22, -0.2), 0, "Button",
			"Press it with your index finger.\nHexRPhysicalButton: no interaction toolkit needed.")

	# The optional Godot XR Tools path: a pickable with HexRInteractableHaptics.
	var side := _table(root, Vector3(1.15, 0, -0.1), Vector3(0.5, 0.04, 0.5), "XRToolsTable")
	side.rotation_degrees = Vector3(0, -50, 0)
	var ball: RigidBody3D = load("res://addons/godot-xr-tools/objects/pickable.tscn").instantiate()
	ball.position = Vector3(0, top + 0.05, 0)
	_add(side, ball, "XRToolsBall")
	_shape(ball, _sphere_shape(0.04))
	_mesh(ball, _sphere(0.04), _mat(Color(0.3, 0.75, 0.95), 0.1, 0.3))
	var ih := HexRInteractableHaptics.new()
	ih.strength = 40.0
	_add(ball, ih, "HexRInteractableHaptics")
	_sign(side, Vector3(0, top + 0.22, -0.15), 0, "XR Tools ball",
			"Pick it up the XR Tools way (pinch).\nHexRInteractableHaptics: squeeze harder, feel more.", 0.3)

	var commands := Node.new()
	commands.set_script(load("res://scripts/tutorial_commands.gd"))
	_add(root, commands, "TutorialCommands")
	var resettable: Array[NodePath] = [root.get_path_to(foam), root.get_path_to(key), root.get_path_to(torch), root.get_path_to(ball)]
	commands.set("resettable", resettable)
	return root


# -- 2. Hospital tutorial -------------------------------------------------------------------

func _hospital() -> Node:
	var root := Node3D.new()
	_begin(root, "HospitalTutorial")
	_common(root, "2 · Hospital Tutorial", "Find the pulse at the wrist and the neck, then hold the heart.")
	var bed := StaticBody3D.new()
	bed.position = Vector3(0, 0, -0.75)
	_add(root, bed, "Bed")
	_mesh(bed, _box(Vector3(1.9, 0.12, 0.8)), _mat(Color(0.85, 0.88, 0.92)), Vector3(0, 0.66, 0), "Mattress")
	_mesh(bed, _box(Vector3(1.95, 0.6, 0.82)), _mat(Color(0.3, 0.32, 0.36), 0.4, 0.5), Vector3(0, 0.3, 0), "Frame")
	_shape(bed, _box_shape(Vector3(1.95, 0.72, 0.82)), Vector3(0, 0.36, 0))

	# A training mannequin lying on its back, head to the left.
	var skin := _mat(Color(0.86, 0.72, 0.62), 0.0, 0.8)
	var man := Node3D.new()
	man.position = Vector3(0, 0.74, 0)
	_add(bed, man, "Mannequin")
	_mesh(man, _sphere(0.1), skin, Vector3(-0.72, 0.08, 0), "Head")
	var neck := _mesh(man, _cyl(0.045, 0.1), skin, Vector3(-0.6, 0.06, 0), "Neck")
	neck.rotation_degrees = Vector3(0, 0, 90)
	var torso := CapsuleMesh.new()
	torso.radius = 0.16
	torso.height = 0.62
	var t := _mesh(man, torso, _mat(Color(0.55, 0.7, 0.85), 0.0, 0.9), Vector3(-0.28, 0.07, 0), "Torso")
	t.rotation_degrees = Vector3(0, 0, 90)
	for sz in [-1, 1]:
		var arm := CapsuleMesh.new()
		arm.radius = 0.04
		arm.height = 0.55
		var a := _mesh(man, arm, skin, Vector3(-0.25, 0.04, sz * 0.22), "Arm%s" % ("Left" if sz > 0 else "Right"))
		a.rotation_degrees = Vector3(0, 0, 90)
		var leg := CapsuleMesh.new()
		leg.radius = 0.07
		leg.height = 0.8
		var l := _mesh(man, leg, _mat(Color(0.25, 0.3, 0.42), 0.0, 0.9), Vector3(0.4, 0.06, sz * 0.09), "Leg%s" % ("Left" if sz > 0 else "Right"))
		l.rotation_degrees = Vector3(0, 0, 90)

	var wrist := _zone(man, "WristPulse", HexRSpecialHaptics.Effect.HEART_BEAT, Vector3(0.02, 0.05, 0.22), _sphere_shape(0.05))
	wrist.heart_beat_pressure = 0.5
	var neck_zone := _zone(man, "NeckPulse", HexRSpecialHaptics.Effect.HEART_BEAT, Vector3(-0.6, 0.08, 0.0), _sphere_shape(0.055))
	neck_zone.heart_beat_pressure = 0.6
	_sign(root, Vector3(-0.35, 1.25, -1.2), 0, "Pulse points",
			"Rest two fingertips on the wrist or the neck.\nHexRSpecialHaptics, heart beat effect.", 0.36)

	var base := StaticBody3D.new()
	base.position = Vector3(0.75, 0.95, -0.35)
	_add(root, base, "ToggleButton")
	_mesh(base, _cyl(0.04, 0.03), _mat(Color(0.2, 0.2, 0.22)), Vector3.ZERO, "Base")
	_shape(base, _cyl_shape(0.04, 0.03))
	var cap := _mesh(base, _cyl(0.028, 0.016), _mat(ORANGE, 0.0, 0.4, 0.4), Vector3(0, 0.022, 0), "Cap")
	var press := HexRPhysicalButton.new()
	press.cap = cap
	press.position = Vector3(0, 0.03, 0)
	_add(base, press, "HexRPhysicalButton")
	_shape(press, _cyl_shape(0.028, 0.02))
	_table(root, Vector3(0.75, 0.17, -0.35), Vector3(0.3, 0.04, 0.3), "ButtonStand")
	var pulse_label := Label3D.new()
	pulse_label.font = load(FONT)
	pulse_label.font_size = 28
	pulse_label.pixel_size = 0.0008
	pulse_label.position = Vector3(0.75, 1.08, -0.35)
	_add(root, pulse_label, "PulseLabel")
	var toggle := Node.new()
	toggle.set_script(load("res://scripts/heartbeat_toggle.gd"))
	_add(root, toggle, "HeartbeatToggle")
	toggle.set("label", pulse_label)
	press.pressed.connect(Callable(toggle, "toggle"), CONNECT_PERSIST)

	var heart_stand := _table(root, Vector3(-0.85, 0.15, -0.2), Vector3(0.3, 0.04, 0.3), "HeartStand")
	var heart := Node3D.new()
	heart.set_script(load("res://scripts/squeezing_heart.gd"))
	heart.position = Vector3(0, 0.88, 0)
	_add(heart_stand, heart, "Heart")
	var shape_root := Node3D.new()
	_add(heart, shape_root, "Shape")
	var red := _mat(Color(0.75, 0.08, 0.12), 0.1, 0.4)
	_mesh(shape_root, _sphere(0.04), red, Vector3(-0.025, 0.02, 0), "LobeLeft")
	_mesh(shape_root, _sphere(0.04), red, Vector3(0.025, 0.02, 0), "LobeRight")
	var tip := CylinderMesh.new()
	tip.top_radius = 0.06
	tip.bottom_radius = 0.0
	tip.height = 0.08
	_mesh(shape_root, tip, red, Vector3(0, -0.03, 0), "Tip")
	var beat := _zone(heart, "BeatZone", HexRSpecialHaptics.Effect.HEART_BEAT, Vector3.ZERO, _sphere_shape(0.075))
	beat.include_palm = true
	var squeeze := _zone(heart, "SqueezeZone", HexRSpecialHaptics.Effect.HAND_SQUEEZE, Vector3.ZERO, _sphere_shape(0.075))
	heart.set("beat_zone", beat)
	heart.set("squeeze_zone", squeeze)
	heart.set("mesh", shape_root)
	_sign(heart_stand, Vector3(0, 1.05, -0.12), 0, "Heart",
			"Hold it in your palm: it beats.\nSqueeze it and it races.", 0.28)
	return root


# -- 3. Water effects -----------------------------------------------------------------------

func _water() -> Node:
	var root := Node3D.new()
	_begin(root, "WaterEffects")
	_common(root, "3 · Water Effects", "Put your fingers in the fountain. Hold your palm up under the cloud.")
	var fountain := StaticBody3D.new()
	fountain.position = Vector3(-0.45, 0, -0.6)
	_add(root, fountain, "Fountain")
	var stone := _mat(Color(0.55, 0.55, 0.58), 0.0, 0.9)
	_mesh(fountain, _cyl(0.32, 0.75), stone, Vector3(0, 0.375, 0), "Pedestal")
	_shape(fountain, _cyl_shape(0.32, 0.75), Vector3(0, 0.375, 0))
	var rim := TorusMesh.new()
	rim.inner_radius = 0.26
	rim.outer_radius = 0.33
	_mesh(fountain, rim, stone, Vector3(0, 0.76, 0), "Rim")
	_mesh(fountain, _cyl(0.27, 0.01), _mat(Color(0.2, 0.45, 0.7, 0.8), 0.2, 0.05), Vector3(0, 0.74, 0), "Water")
	_particles(fountain, "Jet", Vector3(0, 0.78, 0), 220, 1.0, Vector3.UP, 8, Vector2(1.4, 1.7), Vector3(0, -3.0, 0),
			Color(0.6, 0.8, 1.0, 0.85), 0.007)
	var jet_zone := _zone(fountain, "FountainZone", HexRSpecialHaptics.Effect.FOUNTAIN, Vector3(0, 0.98, 0), _cyl_shape(0.07, 0.4))
	jet_zone.name = "FountainZone"
	_sign(root, Vector3(-0.45, 1.45, -1.0), 0, "Fountain",
			"Put your fingers into the jet.\nHexRSpecialHaptics, fountain effect: 18 Hz.", 0.32)

	var cloud := Node3D.new()
	cloud.position = Vector3(0.5, 2.05, -0.45)
	_add(root, cloud, "RainCloud")
	var grey := _mat(Color(0.55, 0.57, 0.62), 0.0, 1.0)
	for i in 6:
		var off := Vector3(cos(i * 1.05) * 0.18, sin(i * 2.3) * 0.04, sin(i * 1.05) * 0.14)
		_mesh(cloud, _sphere(0.13 + 0.03 * (i % 2)), grey, off, "Puff%d" % i)
	_particles(cloud, "Rain", Vector3(0, -0.1, 0), 160, 1.2, Vector3.DOWN, 2, Vector2(1.0, 1.4), Vector3(0, -2.0, 0),
			Color(0.65, 0.8, 1.0, 0.8), 0.005, Vector3(0.2, 0.01, 0.16))
	var rain_zone := _zone(root, "RainZone", HexRSpecialHaptics.Effect.RAIN_DROP, Vector3(0.5, 1.35, -0.45), _box_shape(Vector3(0.45, 1.1, 0.4)))
	rain_zone.haptic_strength = 0.5
	_sign(root, Vector3(0.5, 1.45, -0.95), 0, "Rain",
			"Hold your palm up under the cloud.\nHexRSpecialHaptics, rain drop effect: random drops.", 0.32)
	return root
