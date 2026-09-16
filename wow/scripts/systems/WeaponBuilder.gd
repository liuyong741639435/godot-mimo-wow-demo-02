class_name WeaponBuilder
extends RefCounted
## 在 ArmR/Weapon 节点下重建长剑几何体。

const WD := preload("res://wow/data/WeaponData.gd")


static func build_sword(weapon_root: Node3D, weapon_id: String, instance: Dictionary = {}) -> void:
	if weapon_root == null:
		return
	for c in weapon_root.get_children():
		c.queue_free()
	var w: Dictionary = WD.get_weapon(weapon_id)
	var col: Color = Color(instance.get("color", w["color"]))
	var sc: float = float(instance.get("scale", w.get("scale", 1.0)))

	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.65
	mat.roughness = 0.35

	var edge := StandardMaterial3D.new()
	edge.albedo_color = col.lightened(0.35)
	edge.metallic = 0.8
	edge.roughness = 0.25

	var grip := StandardMaterial3D.new()
	grip.albedo_color = Color(0.25, 0.15, 0.1)
	grip.roughness = 0.9

	# 握柄
	var haft := MeshInstance3D.new()
	haft.name = "Haft"
	var hm := CylinderMesh.new()
	hm.top_radius = 0.04 * sc
	hm.bottom_radius = 0.045 * sc
	hm.height = 0.28 * sc
	haft.mesh = hm
	haft.position = Vector3(0, -0.08, 0.08)
	haft.material_override = grip
	weapon_root.add_child(haft)

	# 护手
	var guard := MeshInstance3D.new()
	guard.name = "Guard"
	var gm := BoxMesh.new()
	gm.size = Vector3(0.28 * sc, 0.05 * sc, 0.08 * sc)
	guard.mesh = gm
	guard.position = Vector3(0, 0.06, 0.12)
	guard.material_override = mat
	weapon_root.add_child(guard)

	# 刃身（细长，微微前倾）
	var blade := MeshInstance3D.new()
	blade.name = "Blade"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.08 * sc, 0.95 * sc, 0.04 * sc)
	blade.mesh = bm
	blade.position = Vector3(0, 0.55 * sc, 0.14)
	blade.rotation_degrees.x = -6
	blade.material_override = mat
	weapon_root.add_child(blade)

	# 刃尖
	var tip := MeshInstance3D.new()
	tip.name = "Tip"
	var tm := BoxMesh.new()
	tm.size = Vector3(0.06 * sc, 0.16 * sc, 0.03 * sc)
	tip.mesh = tm
	tip.position = Vector3(0, 1.08 * sc, 0.16)
	tip.rotation_degrees.x = -10
	tip.material_override = edge
	weapon_root.add_child(tip)

	# 血槽/脊线
	var ridge := MeshInstance3D.new()
	ridge.name = "Ridge"
	var rm := BoxMesh.new()
	rm.size = Vector3(0.02 * sc, 0.85 * sc, 0.045 * sc)
	ridge.mesh = rm
	ridge.position = Vector3(0, 0.55 * sc, 0.14)
	ridge.rotation_degrees.x = -6
	ridge.material_override = edge
	weapon_root.add_child(ridge)

	# 配色肩甲呼应（霸气大剑）
	if sc >= 1.2:
		var spike := MeshInstance3D.new()
		spike.name = "Pommel"
		var sm := SphereMesh.new()
		sm.radius = 0.06 * sc
		spike.mesh = sm
		spike.position = Vector3(0, -0.24 * sc, 0.08)
		spike.material_override = edge
		weapon_root.add_child(spike)


static func build_axe(weapon_root: Node3D) -> void:
	if weapon_root == null:
		return
	for c in weapon_root.get_children():
		c.queue_free()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.58, 0.58, 0.62)
	mat.metallic = 0.5
	mat.roughness = 0.4
	var grip := StandardMaterial3D.new()
	grip.albedo_color = Color(0.35, 0.22, 0.12)

	var haft := MeshInstance3D.new()
	haft.name = "Haft"
	var hm := CylinderMesh.new()
	hm.top_radius = 0.035
	hm.bottom_radius = 0.035
	hm.height = 0.70
	haft.mesh = hm
	haft.position = Vector3(0, -0.18, 0.12)
	haft.rotation_degrees.x = 15
	haft.material_override = grip
	weapon_root.add_child(haft)

	var head := MeshInstance3D.new()
	head.name = "AxeHead"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.28, 0.20, 0.07)
	head.mesh = bm
	head.position = Vector3(0.10, 0.08, 0.28)
	head.material_override = mat
	weapon_root.add_child(head)

	var blade := MeshInstance3D.new()
	blade.name = "AxeBlade"
	var b2 := BoxMesh.new()
	b2.size = Vector3(0.10, 0.24, 0.04)
	blade.mesh = b2
	blade.position = Vector3(0.22, 0.08, 0.28)
	var em := StandardMaterial3D.new()
	em.albedo_color = Color(0.78, 0.80, 0.85)
	em.metallic = 0.7
	em.roughness = 0.25
	blade.material_override = em
	weapon_root.add_child(blade)
