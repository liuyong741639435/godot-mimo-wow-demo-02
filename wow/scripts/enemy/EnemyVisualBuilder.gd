class_name EnemyVisualBuilder
extends RefCounted
## 四种新手怪几何拼接：剪影更清晰、比例更自然。


static func build(parent: Node3D, type_id: String, color: Color) -> void:
	match type_id:
		"boar":
			_build_boar(parent, color)
		"scorpion":
			_build_scorpion(parent, color)
		"raptor":
			_build_raptor(parent, color)
		"beast":
			_build_beast(parent, color)
		_:
			_build_boar(parent, color)


static func _mat(color: Color, rough: float = 0.88) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	return m


static func _box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


static func _sph(parent: Node3D, radius: float, pos: Vector3, color: Color, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mi.mesh = mesh
	mi.position = pos
	mi.scale = scale
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


static func _cap(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


static func _cyl(parent: Node3D, r0: float, r1: float, height: float, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = r0
	mesh.bottom_radius = r1
	mesh.height = height
	mi.mesh = mesh
	mi.position = pos
	mi.rotation = rot
	mi.material_override = _mat(color)
	parent.add_child(mi)
	return mi


static func _glow_sph(parent: Node3D, radius: float, pos: Vector3, color: Color) -> MeshInstance3D:
	var mi := _sph(parent, radius, pos, Color.WHITE)
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.8
	mi.material_override = m
	return mi


## 草原野猪：矮壮、长吻、外翻獠牙、鬃毛
static func _build_boar(parent: Node3D, c: Color) -> void:
	var dark := c.darkened(0.18)
	var light := c.lightened(0.08)
	# 躯干：椭球压扁
	_sph(parent, 0.42, Vector3(0, 0.42, 0), c, Vector3(1.15, 0.85, 1.35))
	# 肩背隆起
	_sph(parent, 0.32, Vector3(0, 0.52, -0.12), light, Vector3(1.1, 0.9, 1.0))
	# 头：长吻向前
	_cap(parent, 0.20, 0.42, Vector3(0, 0.40, 0.48), c, Vector3(90, 0, 0))
	_sph(parent, 0.22, Vector3(0, 0.44, 0.28), c)
	# 鼻镜
	_sph(parent, 0.09, Vector3(0, 0.36, 0.68), dark)
	# 眼
	_glow_sph(parent, 0.035, Vector3(-0.12, 0.50, 0.38), Color(0.9, 0.3, 0.15))
	_glow_sph(parent, 0.035, Vector3(0.12, 0.50, 0.38), Color(0.9, 0.3, 0.15))
	# 外翻獠牙
	_box(parent, Vector3(0.05, 0.14, 0.05), Vector3(-0.14, 0.28, 0.58), Color(0.93, 0.90, 0.78), Vector3(-0.5, 0, -0.35))
	_box(parent, Vector3(0.05, 0.14, 0.05), Vector3(0.14, 0.28, 0.58), Color(0.93, 0.90, 0.78), Vector3(-0.5, 0, 0.35))
	# 耳
	_box(parent, Vector3(0.10, 0.16, 0.04), Vector3(-0.18, 0.58, 0.22), dark, Vector3(0, 0, 0.4))
	_box(parent, Vector3(0.10, 0.16, 0.04), Vector3(0.18, 0.58, 0.22), dark, Vector3(0, 0, -0.4))
	# 背刺鬃毛
	for i in range(5):
		var z := -0.25 + float(i) * 0.12
		_box(parent, Vector3(0.04, 0.14, 0.04), Vector3(0, 0.72 - abs(z) * 0.15, z), Color(0.2, 0.15, 0.1), Vector3(0.2, 0, 0))
	# 短腿
	for x in [-0.22, 0.22]:
		for z in [-0.18, 0.28]:
			_cyl(parent, 0.06, 0.07, 0.28, Vector3(x, 0.14, z), dark)
			_box(parent, Vector3(0.10, 0.05, 0.12), Vector3(x, 0.03, z + 0.02), Color(0.25, 0.2, 0.15))
	# 小尾巴
	_cap(parent, 0.03, 0.18, Vector3(0, 0.48, -0.48), dark, Vector3(1.0, 0, 0))


## 荒漠蝎子：扁身、双螯、弯尾毒针
static func _build_scorpion(parent: Node3D, c: Color) -> void:
	var dark := c.darkened(0.2)
	var accent := Color(0.55, 0.35, 0.15)
	# 头胸部 + 腹部
	_cap(parent, 0.22, 0.55, Vector3(0, 0.22, 0.05), c, Vector3(90, 0, 0))
	_cap(parent, 0.20, 0.40, Vector3(0, 0.20, -0.28), dark, Vector3(90, 0, 0))
	# 头
	_sph(parent, 0.16, Vector3(0, 0.24, 0.32), c)
	_glow_sph(parent, 0.03, Vector3(-0.08, 0.30, 0.42), Color(1, 0.5, 0.1))
	_glow_sph(parent, 0.03, Vector3(0.08, 0.30, 0.42), Color(1, 0.5, 0.1))
	# 双螯
	var sides: Array = [-1.0, 1.0]
	for side in sides:
		var sx: float = float(side) * 0.32
		_cap(parent, 0.05, 0.28, Vector3(sx * 0.7, 0.28, 0.42), c, Vector3(0.4, 0, side * 0.6))
		_box(parent, Vector3(0.16, 0.10, 0.20), Vector3(sx, 0.30, 0.55), accent)
		_box(parent, Vector3(0.08, 0.08, 0.14), Vector3(sx + side * 0.08, 0.34, 0.68), accent.lightened(0.1), Vector3(0, side * 0.3, 0))
		_box(parent, Vector3(0.08, 0.08, 0.14), Vector3(sx + side * 0.08, 0.26, 0.68), accent.lightened(0.1), Vector3(0, side * 0.3, 0))
	# 弯尾
	var tail_pts := [
		Vector3(0, 0.28, -0.45),
		Vector3(0, 0.40, -0.60),
		Vector3(0, 0.55, -0.68),
		Vector3(0, 0.68, -0.60),
		Vector3(0, 0.74, -0.48),
	]
	for i in range(tail_pts.size()):
		var p: Vector3 = tail_pts[i]
		_sph(parent, 0.08 - float(i) * 0.008, p, c.lightened(float(i) * 0.03))
	# 毒针
	_box(parent, Vector3(0.04, 0.16, 0.04), Vector3(0, 0.82, -0.40), Color(0.85, 0.2, 0.15), Vector3(0.8, 0, 0))
	# 六足
	for i in range(3):
		var z := -0.1 + float(i) * 0.18
		for side in sides:
			var lx: float = float(side) * 0.28
			_cap(parent, 0.03, 0.26, Vector3(lx, 0.12, z), dark, Vector3(0, 0, float(side) * 1.1))
			_box(parent, Vector3(0.08, 0.04, 0.10), Vector3(lx + float(side) * 0.08, 0.02, z + 0.04), Color(0.2, 0.15, 0.1))


## 幼年迅猛龙：高瘦双足、长颈、利爪、平衡尾
static func _build_raptor(parent: Node3D, c: Color) -> void:
	var dark := c.darkened(0.2)
	var belly := c.lightened(0.12)
	# 躯干前倾
	_cap(parent, 0.20, 0.55, Vector3(0, 0.95, 0.05), c, Vector3(0.35, 0, 0))
	_sph(parent, 0.22, Vector3(0, 0.88, 0.12), belly, Vector3(0.9, 0.85, 1.0))
	# 颈
	_cap(parent, 0.09, 0.40, Vector3(0, 1.28, 0.22), c, Vector3(0.7, 0, 0))
	# 头：楔形
	_sph(parent, 0.16, Vector3(0, 1.48, 0.38), c, Vector3(0.85, 0.9, 1.15))
	_box(parent, Vector3(0.14, 0.10, 0.28), Vector3(0, 1.44, 0.55), c)
	# 下颚
	_box(parent, Vector3(0.12, 0.06, 0.22), Vector3(0, 1.38, 0.52), dark)
	# 眼
	_glow_sph(parent, 0.04, Vector3(-0.09, 1.54, 0.44), Color(1, 0.55, 0.1))
	_glow_sph(parent, 0.04, Vector3(0.09, 1.54, 0.44), Color(1, 0.55, 0.1))
	# 头冠
	_box(parent, Vector3(0.04, 0.12, 0.18), Vector3(0, 1.62, 0.30), accent_orange(), Vector3(-0.3, 0, 0))
	# 小前肢带爪
	var rsides: Array = [-1.0, 1.0]
	for side in rsides:
		var fs: float = float(side)
		_cap(parent, 0.04, 0.22, Vector3(fs * 0.22, 1.05, 0.22), c, Vector3(0.5, 0, fs * 0.3))
		_box(parent, Vector3(0.04, 0.08, 0.10), Vector3(fs * 0.24, 0.92, 0.32), Color(0.85, 0.82, 0.7))
	# 后腿
	for side in rsides:
		var lx: float = float(side) * 0.14
		_cap(parent, 0.10, 0.35, Vector3(lx, 0.55, 0.02), c)
		_cap(parent, 0.07, 0.30, Vector3(lx, 0.25, -0.02), dark)
		# 脚 + 爪
		_box(parent, Vector3(0.14, 0.08, 0.28), Vector3(lx, 0.06, 0.08), dark)
		_box(parent, Vector3(0.04, 0.04, 0.12), Vector3(lx - 0.04, 0.04, 0.22), Color(0.9, 0.88, 0.75))
		_box(parent, Vector3(0.04, 0.04, 0.12), Vector3(lx + 0.04, 0.04, 0.22), Color(0.9, 0.88, 0.75))
	# 平衡尾
	var i := 0
	while i < 5:
		var t := float(i)
		_cap(parent, 0.08 - t * 0.012, 0.22, Vector3(0, 0.90 - t * 0.04, -0.25 - t * 0.18), c.darkened(t * 0.03), Vector3(1.2, 0, 0))
		i += 1


static func accent_orange() -> Color:
	return Color(0.85, 0.4, 0.12)


## 沙地野兽：四足狼形、尖吻、立耳、蓬尾
static func _build_beast(parent: Node3D, c: Color) -> void:
	var dark := c.darkened(0.22)
	var belly := c.lightened(0.1)
	# 躯干
	_cap(parent, 0.28, 0.75, Vector3(0, 0.55, 0), c, Vector3(90, 0, 0))
	_sph(parent, 0.30, Vector3(0, 0.58, -0.15), c, Vector3(1.0, 0.95, 1.1))
	_sph(parent, 0.24, Vector3(0, 0.48, 0.15), belly, Vector3(0.95, 0.8, 1.0))
	# 颈胸
	_cap(parent, 0.18, 0.35, Vector3(0, 0.62, 0.35), c, Vector3(1.1, 0, 0))
	# 头
	_sph(parent, 0.20, Vector3(0, 0.72, 0.55), c)
	_box(parent, Vector3(0.16, 0.12, 0.30), Vector3(0, 0.66, 0.75), c)
	_box(parent, Vector3(0.12, 0.08, 0.22), Vector3(0, 0.60, 0.72), dark)
	_sph(parent, 0.05, Vector3(0, 0.64, 0.90), Color(0.15, 0.12, 0.1))
	# 眼
	_glow_sph(parent, 0.035, Vector3(-0.10, 0.78, 0.62), Color(1, 0.45, 0.1))
	_glow_sph(parent, 0.035, Vector3(0.10, 0.78, 0.62), Color(1, 0.45, 0.1))
	# 立耳
	_box(parent, Vector3(0.08, 0.20, 0.06), Vector3(-0.12, 0.92, 0.48), dark, Vector3(-0.2, 0, 0.15))
	_box(parent, Vector3(0.08, 0.20, 0.06), Vector3(0.12, 0.92, 0.48), dark, Vector3(-0.2, 0, -0.15))
	# 背脊毛
	for i in range(4):
		_box(parent, Vector3(0.05, 0.12, 0.08), Vector3(0, 0.82, -0.05 - float(i) * 0.12), dark, Vector3(0.25, 0, 0))
	# 四腿
	for x in [-0.20, 0.20]:
		for z in [-0.22, 0.28]:
			_cap(parent, 0.07, 0.42, Vector3(x, 0.28, z), c.darkened(0.08))
			_box(parent, Vector3(0.12, 0.06, 0.16), Vector3(x, 0.04, z + 0.04), dark)
	# 蓬尾
	var i2 := 0
	while i2 < 4:
		var t := float(i2)
		_sph(parent, 0.10 - t * 0.015, Vector3(0, 0.65 - t * 0.05, -0.40 - t * 0.14), c.lightened(0.05 * t))
		i2 += 1
