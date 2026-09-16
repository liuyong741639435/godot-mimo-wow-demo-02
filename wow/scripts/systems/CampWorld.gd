class_name CampWorld
extends Node3D
const GB := preload("res://wow/data/GameBalance.gd")
## 部落营地：NPC 接交任务 + 回谷传送门。

var npc: StaticBody3D
var portal_back: Node3D


func build(player: Node, quests: Node, on_portal: Callable) -> void:
	_build_ground()
	_build_props()
	_build_npc(player, quests)
	_build_portal_back(on_portal)


func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(80, 2, 80)
	col.shape = shape
	col.position = Vector3(0, -1, 0)
	body.add_child(col)
	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.42, 0.28)
	mat.roughness = 0.95
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)


func _build_props() -> void:
	# 帐篷
	for i in range(4):
		var tent := MeshInstance3D.new()
		var tm := PrismMesh.new()
		tm.size = Vector3(3.5, 2.8, 3.5)
		tent.mesh = tm
		var ang := TAU * float(i) / 4.0
		tent.position = Vector3(cos(ang) * 12, 1.4, sin(ang) * 12)
		tent.rotation.y = ang
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.45, 0.25, 0.18)
		tent.material_override = m
		add_child(tent)
	# 火堆
	var fire := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.4
	fm.bottom_radius = 0.6
	fm.height = 0.3
	fire.mesh = fm
	fire.position = Vector3(0, 0.15, 4)
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.9, 0.4, 0.1)
	fmat.emission_enabled = true
	fmat.emission = Color(1, 0.5, 0.1)
	fmat.emission_energy_multiplier = 2.0
	fire.material_override = fmat
	add_child(fire)
	# 旗
	var pole := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.08
	pm.height = 4.5
	pole.mesh = pm
	pole.position = Vector3(-3, 2.25, 0)
	add_child(pole)
	var flag := MeshInstance3D.new()
	var fl := BoxMesh.new()
	fl.size = Vector3(1.4, 0.7, 0.06)
	flag.mesh = fl
	flag.position = Vector3(-2.3, 3.8, 0)
	var flm := StandardMaterial3D.new()
	flm.albedo_color = Color(0.55, 0.1, 0.1)
	flag.material_override = flm
	add_child(flag)


func _build_npc(player: Node, quests: Node) -> void:
	npc = StaticBody3D.new()
	npc.name = "QuestNPC"
	npc.collision_layer = 8
	npc.position = Vector3(0, 0.1, 0)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.8
	col.shape = cap
	col.position = Vector3(0, 0.9, 0)
	npc.add_child(col)

	var vis := Node3D.new()
	vis.name = "Visual"
	npc.add_child(vis)
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.38
	bm.height = 1.5
	body.mesh = bm
	body.position = Vector3(0, 0.85, 0)
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(0.32, 0.5, 0.25)
	body.material_override = bmat
	vis.add_child(body)
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.36, 0.36, 0.34)
	head.mesh = hm
	head.position = Vector3(0, 1.75, 0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.34, 0.55, 0.27)
	head.material_override = hmat
	vis.add_child(head)
	# 肩甲
	var sh := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.5, 0.18, 0.4)
	sh.mesh = sm
	sh.position = Vector3(-0.45, 1.35, 0)
	var smat := StandardMaterial3D.new()
	smat.albedo_color = Color(0.3, 0.2, 0.15)
	sh.material_override = smat
	vis.add_child(sh)
	var sh2 := sh.duplicate()
	sh2.position.x = 0.45
	vis.add_child(sh2)

	var lab := Label3D.new()
	lab.name = "NpcLabel"
	lab.text = "督军顾问·萨尔玛\n[按 F 对话]"
	lab.position = Vector3(0, 2.3, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 20
	lab.outline_size = 6
	lab.modulate = Color(1, 0.9, 0.4)
	npc.add_child(lab)

	var mark := Label3D.new()
	mark.name = "NpcMark"
	mark.text = "?"
	mark.position = Vector3(0, 2.9, 0)
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.font_size = 48
	mark.modulate = Color(1, 0.85, 0.2)
	mark.outline_size = 8
	npc.add_child(mark)

	add_child(npc)

	var zone := Area3D.new()
	zone.name = "NpcZone"
	zone.position = Vector3(0, 0.1, 0)
	var zcol := CollisionShape3D.new()
	var sph := SphereShape3D.new()
	sph.radius = 3.0
	zcol.shape = sph
	zcol.position = Vector3(0, 0.5, 0)
	zone.add_child(zcol)
	npc.add_child(zone)


func _build_portal_back(on_portal: Callable) -> void:
	portal_back = load("res://wow/scripts/systems/Portal.gd").new()
	portal_back.name = "PortalToValley"
	portal_back.set("target_world", "valley")
	portal_back.position = Vector3(8, 0, -6)
	portal_back.set("locked", false)
	add_child(portal_back)
	portal_back.connect("portal_used", on_portal)
