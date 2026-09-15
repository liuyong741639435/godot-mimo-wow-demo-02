class_name OrcVisualBuilder
extends Node3D
## 精细兽人战士：宽肩窄腰、胶囊四肢、分层肩甲、獠牙与战斧。

@export var skin_color := Color(0.34, 0.56, 0.27)
@export var skin_dark := Color(0.26, 0.42, 0.20)
@export var armor_color := Color(0.22, 0.20, 0.18)
@export var armor_light := Color(0.32, 0.30, 0.28)
@export var metal_color := Color(0.58, 0.58, 0.62)
@export var leather_color := Color(0.38, 0.24, 0.12)

var torso: Node3D
var head: Node3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var weapon: Node3D


func _ready() -> void:
	_build()


func _build() -> void:
	# 躯干枢轴（胸腔中心）
	torso = _pivot("Torso", Vector3(0, 1.12, 0))
	add_child(torso)

	# 胸甲：上宽下窄
	torso.add_child(_box("Chest", Vector3(0.82, 0.48, 0.44), Vector3(0, 0.16, 0.02), armor_color))
	torso.add_child(_box("ChestPlate", Vector3(0.70, 0.28, 0.10), Vector3(0, 0.18, 0.22), armor_light))
	torso.add_child(_box("Belly", Vector3(0.52, 0.30, 0.34), Vector3(0, -0.18, 0), skin_dark))
	torso.add_child(_box("Belt", Vector3(0.56, 0.10, 0.36), Vector3(0, -0.36, 0), leather_color))
	torso.add_child(_box("Buckle", Vector3(0.12, 0.10, 0.06), Vector3(0, -0.36, 0.18), metal_color))

	# 肩甲：大垫 + 外沿 + 尖刺
	var sides: Array = [-1.0, 1.0]
	for side in sides:
		var sx: float = float(side) * 0.58
		torso.add_child(_box("Pauldron%s" % ("L" if side < 0 else "R"), Vector3(0.42, 0.26, 0.40), Vector3(sx, 0.30, 0), armor_color))
		torso.add_child(_box("PauldronRim%s" % ("L" if side < 0 else "R"), Vector3(0.46, 0.08, 0.44), Vector3(sx, 0.18, 0), armor_light))
		torso.add_child(_box("Spike%s" % ("L" if side < 0 else "R"), Vector3(0.09, 0.18, 0.09), Vector3(sx + side * 0.04, 0.48, 0), metal_color))

	# 头
	head = _pivot("Head", Vector3(0, 0.58, 0.04))
	torso.add_child(head)
	# 颅骨 + 眉骨 + 下颚
	head.add_child(_box("Skull", Vector3(0.36, 0.34, 0.34), Vector3(0, 0.14, 0.02), skin_color))
	head.add_child(_box("Brow", Vector3(0.38, 0.08, 0.12), Vector3(0, 0.22, 0.14), skin_dark))
	head.add_child(_box("Jaw", Vector3(0.30, 0.14, 0.26), Vector3(0, -0.04, 0.08), skin_dark))
	head.add_child(_box("Chin", Vector3(0.18, 0.08, 0.10), Vector3(0, -0.12, 0.12), skin_color))
	# 獠牙上翘
	head.add_child(_box("TuskL", Vector3(0.07, 0.16, 0.07), Vector3(-0.10, -0.06, 0.16), Color(0.93, 0.90, 0.80)))
	head.add_child(_box("TuskR", Vector3(0.07, 0.16, 0.07), Vector3(0.10, -0.06, 0.16), Color(0.93, 0.90, 0.80)))
	# 耳 / 发髻
	head.add_child(_box("EarL", Vector3(0.06, 0.12, 0.04), Vector3(-0.20, 0.14, -0.02), skin_dark))
	head.add_child(_box("EarR", Vector3(0.06, 0.12, 0.04), Vector3(0.20, 0.14, -0.02), skin_dark))
	head.add_child(_box("Topknot", Vector3(0.10, 0.14, 0.10), Vector3(0, 0.36, -0.06), Color(0.15, 0.12, 0.10)))
	# 发光眼
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.4, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.45, 0.12)
	eye_mat.emission_energy_multiplier = 2.2
	var eye_l := _box("EyeL", Vector3(0.06, 0.04, 0.03), Vector3(-0.09, 0.16, 0.17), Color.WHITE)
	var eye_r := _box("EyeR", Vector3(0.06, 0.04, 0.03), Vector3(0.09, 0.16, 0.17), Color.WHITE)
	eye_l.material_override = eye_mat
	eye_r.material_override = eye_mat
	head.add_child(eye_l)
	head.add_child(eye_r)
	# 头盔带
	head.add_child(_box("HelmBand", Vector3(0.38, 0.07, 0.36), Vector3(0, 0.30, 0), metal_color))

	# 手臂（上臂更粗壮）
	arm_l = _pivot("ArmL", Vector3(-0.58, 0.22, 0))
	torso.add_child(arm_l)
	arm_l.add_child(_capsule("UpperL", 0.11, 0.30, Vector3(0, -0.15, 0), skin_color))
	arm_l.add_child(_capsule("LowerL", 0.09, 0.26, Vector3(0, -0.40, 0), skin_dark))
	arm_l.add_child(_box("FistL", Vector3(0.18, 0.16, 0.18), Vector3(0, -0.56, 0.02), skin_color))
	arm_l.add_child(_box("BracerL", Vector3(0.16, 0.10, 0.16), Vector3(0, -0.34, 0), leather_color))

	arm_r = _pivot("ArmR", Vector3(0.58, 0.22, 0))
	torso.add_child(arm_r)
	arm_r.add_child(_capsule("UpperR", 0.11, 0.30, Vector3(0, -0.15, 0), skin_color))
	arm_r.add_child(_capsule("LowerR", 0.09, 0.26, Vector3(0, -0.40, 0), skin_dark))
	arm_r.add_child(_box("FistR", Vector3(0.18, 0.16, 0.18), Vector3(0, -0.56, 0.02), skin_color))
	arm_r.add_child(_box("BracerR", Vector3(0.16, 0.10, 0.16), Vector3(0, -0.34, 0), leather_color))

	# 战斧
	weapon = _pivot("Weapon", Vector3(0, -0.58, 0.06))
	weapon.rotation_degrees = Vector3(15, 0, 0)
	arm_r.add_child(weapon)
	weapon.add_child(_cyl("Haft", 0.035, 0.70, Vector3(0, -0.18, 0.12), leather_color, 90))
	weapon.add_child(_box("AxeHead", Vector3(0.28, 0.20, 0.07), Vector3(0.10, 0.08, 0.28), metal_color))
	weapon.add_child(_box("AxeBlade", Vector3(0.10, 0.24, 0.04), Vector3(0.22, 0.08, 0.28), Color(0.78, 0.80, 0.85)))
	weapon.add_child(_box("AxeButt", Vector3(0.08, 0.08, 0.08), Vector3(0, -0.48, 0.12), metal_color))

	# 腿：大腿粗、小腿收、靴子带趾
	leg_l = _pivot("LegL", Vector3(-0.20, 0.78, 0))
	add_child(leg_l)
	leg_l.add_child(_capsule("ThighL", 0.13, 0.34, Vector3(0, -0.17, 0), armor_color))
	leg_l.add_child(_capsule("ShinL", 0.10, 0.30, Vector3(0, -0.46, 0), skin_dark))
	leg_l.add_child(_box("KneeL", Vector3(0.16, 0.10, 0.14), Vector3(0, -0.34, 0.04), metal_color))
	leg_l.add_child(_box("BootL", Vector3(0.20, 0.12, 0.30), Vector3(0, -0.66, 0.05), leather_color))
	leg_l.add_child(_box("ToeL", Vector3(0.18, 0.08, 0.08), Vector3(0, -0.68, 0.18), leather_color.darkened(0.15)))

	leg_r = _pivot("LegR", Vector3(0.20, 0.78, 0))
	add_child(leg_r)
	leg_r.add_child(_capsule("ThighR", 0.13, 0.34, Vector3(0, -0.17, 0), armor_color))
	leg_r.add_child(_capsule("ShinR", 0.10, 0.30, Vector3(0, -0.46, 0), skin_dark))
	leg_r.add_child(_box("KneeR", Vector3(0.16, 0.10, 0.14), Vector3(0, -0.34, 0.04), metal_color))
	leg_r.add_child(_box("BootR", Vector3(0.20, 0.12, 0.30), Vector3(0, -0.66, 0.05), leather_color))
	leg_r.add_child(_box("ToeR", Vector3(0.18, 0.08, 0.08), Vector3(0, -0.68, 0.18), leather_color.darkened(0.15)))


func _pivot(node_name: String, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.name = node_name
	n.position = pos
	return n


func _mat(color: Color, rough: float = 0.78) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = rough
	mat.metallic = 0.05
	return mat


func _box(node_name: String, size: Vector3, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(color)
	return mi


func _capsule(node_name: String, radius: float, height: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.material_override = _mat(color)
	return mi


func _cyl(node_name: String, radius: float, height: float, pos: Vector3, color: Color, rot_x_deg: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.rotation_degrees.x = rot_x_deg
	mi.material_override = _mat(color)
	return mi
