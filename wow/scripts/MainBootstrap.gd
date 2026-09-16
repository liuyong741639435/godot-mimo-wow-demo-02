extends Node3D
const GB := preload("res://wow/data/GameBalance.gd")
## Batch1 bootstrap: environment, ground, player, HUD, dummies

const OrcVisualBuilderScript := preload("res://wow/scripts/player/OrcVisualBuilder.gd")
const PlayerScript := preload("res://wow/scripts/player/Player.gd")
const PlayerStatsScript := preload("res://wow/scripts/player/PlayerStats.gd")
const SkillControllerScript := preload("res://wow/scripts/player/SkillController.gd")
const PlayerAnimatorScript := preload("res://wow/scripts/player/PlayerAnimator.gd")
const DummyEnemyScript := preload("res://wow/scripts/enemy/DummyEnemy.gd")
const EnemyBaseScript := preload("res://wow/scripts/enemy/EnemyBase.gd")
const EnemyVisualBuilderScript := preload("res://wow/scripts/enemy/EnemyVisualBuilder.gd")
const PlayerHUDScript := preload("res://wow/ui/PlayerHUD.gd")
const QuestSystemScript := preload("res://wow/scripts/systems/QuestSystem.gd")
const AudioManager := preload("res://wow/scripts/systems/AudioManager.gd")
const PortalScript := preload("res://wow/scripts/systems/Portal.gd")
const CampWorldScript := preload("res://wow/scripts/systems/CampWorld.gd")

var player: CharacterBody3D
var hud: CanvasLayer
var quests: Node
var terrain: Node3D = null
var valley_world: Node3D
var camp_world: Node3D
var current_world := "valley"
var portal_to_camp: Node3D
var _npc_zone_near := false


func _ready() -> void:
	_build_environment()
	_try_build_terrain3d()
	_build_ground()
	_build_player()
	_build_hud()
	_build_enemies()
	_build_deco()
	_setup_quests()
	_build_camp_and_portal()


func _try_build_terrain3d() -> bool:
	if not ClassDB.can_instantiate("Terrain3D"):
		return false
	var t: Node3D = ClassDB.instantiate("Terrain3D")
	t.name = "Terrain3D"
	t.set("data_directory", "res://demo/data")
	var assets = load("res://demo/data/assets.tres")
	if assets:
		t.set("assets", assets)
	t.set("collision_layer", 1)
	t.set("collision_mask", 3)
	add_child(t)
	terrain = t
	_apply_desert_terrain_tint(t)
	return true


func _apply_desert_terrain_tint(t: Node3D) -> void:
	# 用 macro variation 把岩石高地染成杜隆塔尔沙土色
	var mat = t.get("material")
	if mat == null:
		return
	# 杜隆塔尔：暖沙、赭石、干草黄
	var sand := Color(0.78, 0.62, 0.38)
	var ochre := Color(0.72, 0.48, 0.28)
	var dust := Color(0.85, 0.72, 0.48)
	if mat.has_method("set_shader_parameter"):
		mat.set_shader_parameter("macro_variation1", sand)
		mat.set_shader_parameter("macro_variation2", ochre)
		mat.set_shader_parameter("enable_macro_variation", true)
		mat.set_shader_parameter("macro_variation_slope", 0.45)
		mat.set_shader_parameter("auto_base_texture", 0)
		mat.set_shader_parameter("auto_overlay_texture", 1)
		mat.set_shader_parameter("auto_slope", 0.55)
		mat.set_shader_parameter("world_noise_height", 18.0)
	# 直接写属性（部分版本走属性而不是 set_shader_parameter）
	if "macro_variation1" in mat:
		mat.macro_variation1 = sand
	if "macro_variation2" in mat:
		mat.macro_variation2 = ochre
	# 尝试通过 _shader_parameters 字典
	var sp = mat.get("_shader_parameters")
	if sp is Dictionary:
		var d: Dictionary = sp.duplicate()
		d["macro_variation1"] = sand
		d["macro_variation2"] = ochre
		d["macro_variation_slope"] = 0.45
		d["enable_macro_variation"] = true
		d["auto_base_texture"] = 0
		d["auto_overlay_texture"] = 1
		d["auto_slope"] = 0.55
		d["world_noise_height"] = 16.0
		d["world_noise_scale"] = 8.0
		mat.set("_shader_parameters", d)



func _ground_y(x: float, z: float) -> float:
	if terrain and terrain.get("data"):
		var data = terrain.get("data")
		if data and data.has_method("get_height"):
			var h: float = data.get_height(Vector3(x, 0, z))
			# 无效区域常返回很负的值
			if h > -9000.0:
				return h + 0.05
	return 0.05




func _build_environment() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-52, 40, 0)
	sun.light_energy = 1.35
	sun.light_color = Color(1.0, 0.92, 0.78)
	sun.shadow_enabled = true
	add_child(sun)

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	# 杜隆塔尔：偏黄沙尘天空
	sky_mat.sky_top_color = Color(0.45, 0.55, 0.65)
	sky_mat.sky_horizon_color = Color(0.85, 0.72, 0.48)
	sky_mat.ground_bottom_color = Color(0.45, 0.32, 0.18)
	sky_mat.ground_horizon_color = Color(0.78, 0.62, 0.38)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.65
	env.ambient_light_color = Color(0.9, 0.82, 0.65)
	env.fog_enabled = true
	env.fog_light_color = Color(0.82, 0.7, 0.48)
	env.fog_density = 0.0035
	env.fog_sky_affect = 0.35
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.08
	env.adjustment_contrast = 1.05
	env.adjustment_brightness = 1.02
	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	we.environment = env
	add_child(we)



func _build_ground() -> void:
	var body := StaticBody3D.new()
	body.name = "Ground"
	body.collision_layer = 1
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(220, 2, 220)
	col.shape = shape
	col.position = Vector3(0, -1, 0)
	body.add_child(col)

	var mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(220, 220)
	plane.subdivide_width = 8
	plane.subdivide_depth = 8
	mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.64, 0.53, 0.34)
	mat.roughness = 0.95
	var gtex: Texture2D = load("res://demo/assets/textures/ground037_alb_ht.png")
	if gtex:
		mat.albedo_texture = gtex
		mat.uv1_scale = Vector3(24, 24, 1)
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)
	# Terrain3D 接管地表时隐藏几何地面网格，保留碰撞兜底
	if terrain:
		mesh.visible = false

	# 山谷两侧高墙：仅在无 Terrain3D 时生成（Terrain3D 自带山体）
	if terrain == null:
		var wall_sides: Array = [-1.0, 1.0]
		for side in wall_sides:
			var fs: float = float(side)
			var wall := StaticBody3D.new()
			wall.name = "ValleyWall_%d" % int(fs)
			wall.collision_layer = 1
			var wc := CollisionShape3D.new()
			var ws := BoxShape3D.new()
			ws.size = Vector3(28, 18, 140)
			wc.shape = ws
			wc.position = Vector3(0, 6, 0)
			wall.add_child(wc)
			var wm := MeshInstance3D.new()
			var wb := BoxMesh.new()
			wb.size = Vector3(28, 18, 140)
			wm.mesh = wb
			var wmat := StandardMaterial3D.new()
			wmat.albedo_color = Color(0.68, 0.52, 0.32)
			wmat.roughness = 1.0
			var rtex: Texture2D = load("res://demo/assets/textures/rock023_alb_ht.png")
			if rtex:
				wmat.albedo_texture = rtex
				wmat.uv1_scale = Vector3(6, 3, 12)
			wm.material_override = wmat
			wall.add_child(wm)
			wall.position = Vector3(fs * 52.0, 4, 0)
			add_child(wall)
			# 墙顶不规则岩块
			var wi := 0
			while wi < 8:
				var rock := MeshInstance3D.new()
				var rb := BoxMesh.new()
				var s := randf_range(4, 9)
				rb.size = Vector3(s, s * randf_range(0.6, 1.4), s * randf_range(0.8, 1.5))
				rock.mesh = rb
				rock.position = Vector3(fs * randf_range(42, 48), randf_range(10, 14), -50.0 + float(wi) * 14.0)
				rock.rotation.y = randf()
				var rmat := StandardMaterial3D.new()
				rmat.albedo_color = Color(0.62, 0.48, 0.30)
				if rtex:
					rmat.albedo_texture = rtex
				rmat.roughness = 1.0
				rock.material_override = rmat
				add_child(rock)
				wi += 1

	# 谷中起伏（贴地）
	for i in range(8):
		var hill := StaticBody3D.new()
		hill.collision_layer = 1
		var hc2 := CollisionShape3D.new()
		var hs2 := SphereShape3D.new()
		var r2 := randf_range(2.0, 5.0)
		hs2.radius = r2
		hc2.shape = hs2
		var hx := randf_range(-30, 30)
		var hz := randf_range(-45, 45)
		if Vector2(hx, hz).length() < 14.0:
			hx += 18.0
		var hy := _ground_y(hx, hz)
		hill.position = Vector3(hx, hy - r2 * 0.55, hz)
		hill.add_child(hc2)
		var hm2 := MeshInstance3D.new()
		var sm2 := SphereMesh.new()
		sm2.radius = r2
		sm2.height = r2 * 2.0
		hm2.mesh = sm2
		var hmat2 := StandardMaterial3D.new()
		hmat2.albedo_color = Color(0.72, 0.58, 0.36)
		if gtex:
			hmat2.albedo_texture = gtex
		hmat2.roughness = 1.0
		hm2.material_override = hmat2
		hill.add_child(hm2)
		add_child(hill)

	# 低台可跳（贴地）
	for i in range(8):
		var plat := StaticBody3D.new()
		plat.collision_layer = 1
		var pc := CollisionShape3D.new()
		var ps := BoxShape3D.new()
		ps.size = Vector3(2.8, 1.1, 2.8)
		pc.shape = ps
		plat.add_child(pc)
		var ang := TAU * float(i) / 8.0
		var pxx := cos(ang) * 16.0
		var pzz := sin(ang) * 16.0
		plat.position = Vector3(pxx, _ground_y(pxx, pzz) + 0.5, pzz)
		var pm := MeshInstance3D.new()
		var pb := BoxMesh.new()
		pb.size = Vector3(2.8, 1.1, 2.8)
		pm.mesh = pb
		var pmat := StandardMaterial3D.new()
		pmat.albedo_color = Color(0.65, 0.55, 0.40)
		pm.material_override = pmat
		plat.add_child(pm)
		add_child(plat)

	# 出生点石堆营地
	var camp := Node3D.new()
	camp.name = "SpawnCamp"
	camp.position = Vector3(0, _ground_y(0, 4), 4)
	for i in range(5):
		var c := MeshInstance3D.new()
		var cb := BoxMesh.new()
		var cs := randf_range(0.5, 1.2)
		cb.size = Vector3(cs, cs * 0.7, cs)
		c.mesh = cb
		var ang2 := TAU * float(i) / 5.0
		c.position = Vector3(cos(ang2) * 2.2, 0.3, sin(ang2) * 2.2)
		c.rotation.y = randf()
		var cm := StandardMaterial3D.new()
		cm.albedo_color = Color(0.62, 0.52, 0.38)
		c.material_override = cm
		camp.add_child(c)
	# 旗杆
	var pole := MeshInstance3D.new()
	var pb2 := CylinderMesh.new()
	pb2.top_radius = 0.06
	pb2.bottom_radius = 0.08
	pb2.height = 3.2
	pole.mesh = pb2
	pole.position = Vector3(0, 1.6, 0)
	var pole_m := StandardMaterial3D.new()
	pole_m.albedo_color = Color(0.35, 0.25, 0.15)
	pole.material_override = pole_m
	camp.add_child(pole)
	var flag := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(1.1, 0.55, 0.05)
	flag.mesh = fb
	flag.position = Vector3(0.55, 2.7, 0)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.55, 0.12, 0.1)
	flag.material_override = fm
	camp.add_child(flag)
	add_child(camp)



func _build_deco() -> void:
	var i := 0
	while i < 24:
		var rock := MeshInstance3D.new()
		var bm := BoxMesh.new()
		var s := randf_range(0.4, 1.8)
		bm.size = Vector3(s, s * randf_range(0.5, 1.2), s * randf_range(0.7, 1.3))
		rock.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.72, 0.58, 0.38)
		mat.roughness = 0.95
		var rtex: Texture2D = load("res://demo/assets/textures/rock023_alb_ht.png")
		if rtex:
			mat.albedo_texture = rtex
		rock.material_override = mat
		var ang := randf() * TAU
		var dist := randf_range(10, 70)
		var px := cos(ang) * dist
		var pz := sin(ang) * dist
		rock.position = Vector3(px, _ground_y(px, pz) + s * 0.25, pz)
		rock.rotation.y = randf() * TAU
		add_child(rock)
		i += 1

	# 仙人掌
	var ci := 0
	while ci < 10:
		var cx := randf_range(-40, 40)
		var cz := randf_range(-40, 40)
		if Vector2(cx, cz).length() < 8.0:
			ci += 1
			continue
		var cy := _ground_y(cx, cz)
		var cactus := Node3D.new()
		cactus.position = Vector3(cx, cy, cz)
		var green := Color(0.28, 0.48, 0.22)
		var body := MeshInstance3D.new()
		var cb := CylinderMesh.new()
		cb.top_radius = 0.18
		cb.bottom_radius = 0.22
		cb.height = 1.4
		body.mesh = cb
		body.position = Vector3(0, 0.7, 0)
		var cm := StandardMaterial3D.new()
		cm.albedo_color = green
		body.material_override = cm
		cactus.add_child(body)
		var arm_sides: Array = [-1.0, 1.0]
		for side in arm_sides:
			var fs: float = float(side)
			var arm := MeshInstance3D.new()
			var ab := CylinderMesh.new()
			ab.top_radius = 0.10
			ab.bottom_radius = 0.10
			ab.height = 0.55
			arm.mesh = ab
			arm.position = Vector3(fs * 0.28, 0.85, 0)
			arm.rotation_degrees.z = fs * 70
			arm.material_override = cm
			cactus.add_child(arm)
		add_child(cactus)
		ci += 1

	# 兽骨
	var bi := 0
	while bi < 6:
		var bx := randf_range(-35, 35)
		var bz := randf_range(-35, 35)
		var by := _ground_y(bx, bz)
		var bone_m := StandardMaterial3D.new()
		bone_m.albedo_color = Color(0.92, 0.90, 0.80)
		for k in range(3):
			var bone := MeshInstance3D.new()
			var bb := BoxMesh.new()
			bb.size = Vector3(0.08, 0.08, randf_range(0.4, 0.7))
			bone.mesh = bb
			bone.position = Vector3(bx + randf_range(-0.3, 0.3), by + 0.05, bz + randf_range(-0.3, 0.3))
			bone.rotation.y = randf() * TAU
			bone.material_override = bone_m
			add_child(bone)
		var skull := MeshInstance3D.new()
		var sk := SphereMesh.new()
		sk.radius = 0.18
		sk.height = 0.28
		skull.mesh = sk
		skull.position = Vector3(bx, by + 0.12, bz)
		skull.material_override = bone_m
		add_child(skull)
		bi += 1


func _build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.set_script(PlayerScript)
	player.collision_layer = 2
	player.collision_mask = 1 | 4
	player.position = Vector3(0, _ground_y(0, 0), 0)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.38
	cap.height = 1.85
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	player.add_child(col)

	var stats := Node.new()
	stats.name = "PlayerStats"
	stats.set_script(PlayerStatsScript)
	player.add_child(stats)

	var skills := Node.new()
	skills.name = "SkillController"
	skills.set_script(SkillControllerScript)
	player.add_child(skills)

	var animator := Node.new()
	animator.name = "PlayerAnimator"
	animator.set_script(PlayerAnimatorScript)
	player.add_child(animator)

	var visual := Node3D.new()
	visual.name = "Visual"
	player.add_child(visual)

	var builder := Node3D.new()
	builder.name = "OrcVisual"
	builder.set_script(OrcVisualBuilderScript)
	visual.add_child(builder)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	player.add_child(cam)

	var name_label := Label3D.new()
	name_label.name = "NameLabel"
	name_label.text = "兽人战士 Lv1"
	name_label.position = Vector3(0, 2.15, 0)
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.font_size = 28
	name_label.outline_size = 6
	player.add_child(name_label)

	add_child(player)


func _build_hud() -> void:
	hud = CanvasLayer.new()
	hud.name = "HUD"
	hud.set_script(PlayerHUDScript)
	add_child(hud)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(root)

	var panel := PanelContainer.new()
	panel.name = "PlayerPanel"
	panel.position = Vector2(16, 420)
	panel.custom_minimum_size = Vector2(300, 170)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.75)
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	root.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)

	var level_label := Label.new()
	level_label.name = "LevelLabel"
	level_label.unique_name_in_owner = true
	level_label.text = "兽人战士 Lv1"
	level_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(level_label)

	vbox.add_child(_make_bar_row("生命", "HPBar", "HPText", Color(0.85, 0.2, 0.15)))
	vbox.add_child(_make_bar_row("怒气", "RageBar", "RageText", Color(0.95, 0.75, 0.15)))
	vbox.add_child(_make_bar_row("经验", "ExpBar", "ExpText", Color(0.4, 0.8, 0.35)))

	var combat_label := Label.new()
	combat_label.name = "CombatLabel"
	combat_label.unique_name_in_owner = true
	combat_label.text = "脱离战斗"
	combat_label.add_theme_font_size_override("font_size", 14)
	combat_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))
	vbox.add_child(combat_label)

	var skill_bar := HBoxContainer.new()
	skill_bar.name = "SkillBar"
	skill_bar.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	skill_bar.position = Vector2(-340, -72)
	skill_bar.add_theme_constant_override("separation", 8)
	root.add_child(skill_bar)

	# id, hotkey, title, unlock_level
	var skills_def := [
		["heroic", "1", "英勇打击", 1],
		["charge", "2", "冲锋", 1],
		["intercept", "3", "拦截", 3],
		["whirlwind", "4", "旋风斩", 5],
		["potion", "5", "药水", 1],
		["rend", "6", "撕裂", 6],
		["thunder", "7", "雷霆一击", 7],
		["execute", "8", "处决", 8],
		["mortal", "9", "致死打击", 9],
		["bladestorm", "0", "剑刃风暴", 10],
	]
	for sd in skills_def:
		var slot := Control.new()
		slot.name = "SkillSlot_%s" % sd[0]
		slot.custom_minimum_size = Vector2(56, 56)
		slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		skill_bar.add_child(slot)

		var bg := Panel.new()
		bg.name = "Bg"
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var s2 := StyleBoxFlat.new()
		s2.bg_color = Color(0.12, 0.12, 0.15, 0.9)
		s2.border_color = Color(0.55, 0.45, 0.2)
		s2.set_border_width_all(2)
		s2.set_corner_radius_all(6)
		bg.add_theme_stylebox_override("panel", s2)
		slot.add_child(bg)

		var lbl := Label.new()
		lbl.name = "Title"
		lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lbl.text = "%s\n%s" % [sd[1], sd[2]]
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 11)
		slot.add_child(lbl)

		var cd := ProgressBar.new()
		cd.name = "CdOverlay"
		cd.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd.show_percentage = false
		cd.min_value = 0
		cd.max_value = 1
		cd.value = 0
		cd.fill_mode = ProgressBar.FILL_TOP_TO_BOTTOM
		cd.mouse_filter = Control.MOUSE_FILTER_IGNORE
		cd.visible = false
		var cdbg := StyleBoxFlat.new()
		cdbg.bg_color = Color(0, 0, 0, 0.55)
		cd.add_theme_stylebox_override("background", cdbg)
		var cdfill := StyleBoxFlat.new()
		cdfill.bg_color = Color(0.15, 0.15, 0.2, 0.75)
		cd.add_theme_stylebox_override("fill", cdfill)
		slot.add_child(cd)

		var cd_text := Label.new()
		cd_text.name = "CdText"
		cd_text.set_anchors_preset(Control.PRESET_FULL_RECT)
		cd_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cd_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		cd_text.add_theme_font_size_override("font_size", 16)
		cd_text.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		cd_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		slot.add_child(cd_text)

		var lock := ColorRect.new()
		lock.name = "LockOverlay"
		lock.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock.color = Color(0, 0, 0, 0.65)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var lock_lbl := Label.new()
		lock_lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		lock_lbl.text = "Lv%d" % int(sd[3])
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_font_size_override("font_size", 12)
		lock.add_child(lock_lbl)
		lock.visible = int(sd[3]) > 1
		slot.add_child(lock)


	var pot := VBoxContainer.new()
	pot.name = "PotionBox"
	pot.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	pot.position = Vector2(-120, -100)
	root.add_child(pot)
	var pot_title := Label.new()
	pot_title.text = "[5] 治疗药水"
	pot_title.add_theme_font_size_override("font_size", 13)
	pot.add_child(pot_title)
	var potion_label := Label.new()
	potion_label.name = "PotionLabel"
	potion_label.unique_name_in_owner = true
	potion_label.text = "x3"
	potion_label.add_theme_font_size_override("font_size", 18)
	pot.add_child(potion_label)
	var potion_cd := Label.new()
	potion_cd.name = "PotionCdLabel"
	potion_cd.unique_name_in_owner = true
	potion_cd.add_theme_color_override("font_color", Color(1, 0.6, 0.3))
	pot.add_child(potion_cd)

	var target := PanelContainer.new()
	target.name = "TargetFrame"
	target.unique_name_in_owner = true
	target.set_anchors_preset(Control.PRESET_CENTER_TOP)
	target.position = Vector2(-140, 24)
	target.custom_minimum_size = Vector2(280, 70)
	target.visible = false
	var ts := StyleBoxFlat.new()
	ts.bg_color = Color(0.05, 0.05, 0.08, 0.8)
	ts.set_corner_radius_all(8)
	ts.border_color = Color(0.7, 0.5, 0.2)
	ts.set_border_width_all(1)
	target.add_theme_stylebox_override("panel", ts)
	root.add_child(target)
	var tv := VBoxContainer.new()
	target.add_child(tv)
	var tname := Label.new()
	tname.name = "TargetName"
	tname.unique_name_in_owner = true
	tname.text = "目标"
	tv.add_child(tname)
	var thp := Label.new()
	thp.name = "TargetHp"
	thp.unique_name_in_owner = true
	tv.add_child(thp)
	var tbar := ProgressBar.new()
	tbar.name = "TargetHpBar"
	tbar.unique_name_in_owner = true
	tbar.show_percentage = false
	tbar.custom_minimum_size = Vector2(240, 14)
	var tbs := StyleBoxFlat.new()
	tbs.bg_color = Color(0.8, 0.15, 0.1)
	tbar.add_theme_stylebox_override("fill", tbs)
	tv.add_child(tbar)

	var toast := Label.new()
	toast.name = "ToastLabel"
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.position = Vector2(-160, 110)
	toast.custom_minimum_size = Vector2(320, 30)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_font_size_override("font_size", 20)
	toast.add_theme_color_override("font_color", Color(1, 0.9, 0.4))
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	toast.add_theme_constant_override("outline_size", 6)
	toast.visible = false
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(toast)

	var hint := Label.new()
	hint.text = "WASD移动 | 右键视角 | Space跳跃 | Tab/左键选中 | 1-5技能"
	hint.set_anchors_preset(Control.PRESET_CENTER_TOP)
	hint.position = Vector2(-220, 8)
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	root.add_child(hint)

	get_tree().process_frame.connect(func() -> void:
		if player and hud.has_method("bind_player"):
			hud.bind_player(player)
		if player and player.has_signal("target_changed"):
			player.target_changed.connect(_on_target_changed)
	, CONNECT_ONE_SHOT)


func _make_bar_row(title: String, bar_name: String, text_name: String, fill: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var t := Label.new()
	t.text = title
	t.custom_minimum_size = Vector2(36, 0)
	t.add_theme_font_size_override("font_size", 13)
	row.add_child(t)
	var bar := ProgressBar.new()
	bar.name = bar_name
	bar.unique_name_in_owner = true
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(140, 16)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill
	bar.add_theme_stylebox_override("fill", fill_style)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.2, 0.2, 0.22)
	bar.add_theme_stylebox_override("background", bg)
	row.add_child(bar)
	var txt := Label.new()
	txt.name = text_name
	txt.unique_name_in_owner = true
	txt.text = "-"
	txt.add_theme_font_size_override("font_size", 12)
	row.add_child(txt)
	return row


func _build_enemies() -> void:
	# 拉开站位：同种怪间距 >= 12m，避免一拉一群
	var jobs: Array = []
	# 野猪：谷口分散
	var boar_spots := [
		Vector3(14, 0.1, 10),
		Vector3(22, 0.1, 4),
		Vector3(8, 0.1, 18),
		Vector3(18, 0.1, 16),
	]
	for s in boar_spots:
		jobs.append(["boar", s])
	# 蝎子：另一侧更远
	var sc_spots := [
		Vector3(-20, 0.1, 16),
		Vector3(-30, 0.1, 8),
		Vector3(-16, 0.1, 26),
		Vector3(-28, 0.1, 22),
	]
	for s in sc_spots:
		jobs.append(["scorpion", s])
	# 迅猛龙
	var rp_spots := [
		Vector3(24, 0.1, -18),
		Vector3(34, 0.1, -10),
		Vector3(20, 0.1, -28),
		Vector3(32, 0.1, -24),
	]
	for s in rp_spots:
		jobs.append(["raptor", s])
	# 野兽
	var bs_spots := [
		Vector3(-18, 0.1, -24),
		Vector3(-28, 0.1, -16),
		Vector3(-14, 0.1, -34),
		Vector3(-26, 0.1, -30),
	]
	for s in bs_spots:
		jobs.append(["beast", s])
	# 精英怪：每种 1 只，放在该区域稍偏位置
	jobs.append(["boar", Vector3(26, 0.1, 14), true])
	jobs.append(["scorpion", Vector3(-34, 0.1, 28), true])
	jobs.append(["raptor", Vector3(38, 0.1, -28), true])
	jobs.append(["beast", Vector3(-32, 0.1, -36), true])
	# 中期怪 Lv6-8（山谷深处）
	var mid_spots := [
		["kolkar", Vector3(40, 0.1, 20)],
		["kolkar", Vector3(48, 0.1, 8)],
		["kolkar", Vector3(36, 0.1, 32)],
		["harpy", Vector3(-42, 0.1, -8)],
		["harpy", Vector3(-50, 0.1, 4)],
		["harpy", Vector3(-38, 0.1, -18)],
		["lizard", Vector3(45, 0.1, -35)],
		["lizard", Vector3(55, 0.1, -22)],
		["boss", Vector3(0, 0.1, -55)],
	]
	for ms in mid_spots:
		jobs.append([ms[0], ms[1]])
	var i := 0
	while i < jobs.size():
		var elite: bool = jobs[i].size() > 2 and bool(jobs[i][2])
		_spawn_enemy(str(jobs[i][0]), jobs[i][1], i, elite)
		i += 1


func _spawn_enemy(type_id: String, pos: Vector3, idx: int, elite: bool = false) -> void:
	pos.y = _ground_y(pos.x, pos.z)
	var e: EnemyBase = EnemyBase.new()
	e.name = "Enemy_%s_%d%s" % [type_id, idx, ("_elite" if elite else "")]
	e.collision_layer = 4
	e.collision_mask = 1
	e.position = pos
	e.type_id = type_id
	e.is_elite = elite

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.4
	col.shape = cap
	col.position = Vector3(0, 0.7, 0)
	e.add_child(col)

	var vis := Node3D.new()
	vis.name = "Visual"
	e.add_child(vis)

	var lab := Label3D.new()
	lab.name = "Label3D"
	lab.position = Vector3(0, 2.0, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 20
	lab.outline_size = 5
	e.add_child(lab)

	var bar_root := MeshInstance3D.new()
	bar_root.name = "HpBar"
	var bg_mesh := BoxMesh.new()
	bg_mesh.size = Vector3(1.0, 0.1, 0.02)
	bar_root.mesh = bg_mesh
	bar_root.position = Vector3(0, 1.85, 0)
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.1, 0.1, 0.1)
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bar_root.material_override = bg_mat
	e.add_child(bar_root)

	var fill := MeshInstance3D.new()
	fill.name = "Fill"
	var fill_mesh := BoxMesh.new()
	fill_mesh.size = Vector3(1.0, 0.08, 0.025)
	fill.mesh = fill_mesh
	fill.position = Vector3(0, 0, 0.01)
	var fill_mat := StandardMaterial3D.new()
	fill_mat.albedo_color = Color(0.85, 0.15, 0.1)
	fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill.material_override = fill_mat
	bar_root.add_child(fill)

	add_child(e)
	e.configure(type_id, elite)
	var data: Dictionary = GB.ENEMY_TYPES[type_id]
	EnemyVisualBuilderScript.build(vis, type_id, data["body_color"])
	if e.has_method("_refresh_label"):
		e._refresh_label()
	if elite:
		lab.position = Vector3(0, 2.3, 0)
		bar_root.position = Vector3(0, 2.15, 0)




func _setup_quests() -> void:
	quests = Node.new()
	quests.name = "QuestSystem"
	quests.set_script(QuestSystemScript)
	add_child(quests)

	# quest panel UI
	var panel := PanelContainer.new()
	panel.name = "QuestPanel"
	panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	panel.position = Vector2(-280, 40)
	panel.custom_minimum_size = Vector2(250, 110)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.8)
	style.set_corner_radius_all(8)
	style.set_border_width_all(1)
	style.border_color = Color(0.55, 0.45, 0.25)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var root: Control = hud.get_node("Root")
	root.add_child(panel)
	var ql := Label.new()
	ql.name = "QuestLabel"
	ql.text = "任务加载中..."
	ql.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ql.add_theme_font_size_override("font_size", 13)
	panel.add_child(ql)

	quests.quest_updated.connect(func(_id: int, qname: String, desc: String, prog: int, goal: int, reward: int) -> void:
		if goal <= 0:
			ql.text = "任务：%s\n%s" % [qname, desc]
		else:
			ql.text = "任务：%s\n%s  %d/%d\n奖励经验 %d" % [qname, desc, prog, goal, reward]
		if quests and "current_index" in quests and quests.current_index < QuestSystemScript.QUESTS.size():
			_refresh_quest_beacons(str(QuestSystemScript.QUESTS[quests.current_index]["kill_type"]))
		else:
			_clear_quest_beacons()
	)
	quests.quest_completed.connect(func(_id: int, exp: int) -> void:
		if player and player.get_parent():
			AudioManager.play(player.get_parent(), "quest")
		if hud and hud.has_method("show_toast"):
			hud.show_toast("任务完成！经验 +%d" % exp, Color(0.4, 1, 0.5))
	)

	# connect enemy deaths
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.has_signal("died_signal") and not e.died_signal.is_connected(_on_enemy_died):
			e.died_signal.connect(_on_enemy_died)

	get_tree().process_frame.connect(func() -> void:
		if player and quests:
			quests.start(player)
	, CONNECT_ONE_SHOT)


func _clear_quest_beacons() -> void:
	for e in get_tree().get_nodes_in_group("enemies"):
		var b := e.get_node_or_null("QuestBeacon") if e is Node else null
		if b:
			b.queue_free()


func _refresh_quest_beacons(kill_type: String) -> void:
	_clear_quest_beacons()
	for e in get_tree().get_nodes_in_group("enemies"):
		if not (e is EnemyBase):
			continue
		if e.is_elite or not e.is_alive():
			continue
		if str(e.type_id) != kill_type:
			continue
		var beam := MeshInstance3D.new()
		beam.name = "QuestBeacon"
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.15
		cyl.bottom_radius = 0.35
		cyl.height = 4.5
		beam.mesh = cyl
		beam.position = Vector3(0, 2.8, 0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.85, 0.2, 0.35)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.8, 0.15)
		mat.emission_energy_multiplier = 1.2
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		beam.material_override = mat
		e.add_child(beam)
		# 顶部小叹号
		var mark := Label3D.new()
		mark.name = "QuestMark"
		mark.text = "!"
		mark.position = Vector3(0, 5.4, 0)
		mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		mark.font_size = 48
		mark.modulate = Color(1, 0.9, 0.2)
		mark.outline_size = 10
		e.add_child(mark)


func _on_enemy_died(enemy: Node, _killer: Node) -> void:
	if enemy and "type_id" in enemy and quests:
		quests.on_enemy_killed(enemy.type_id)
		# 刷新任务光柱
		if quests.current_index < QuestSystemScript.QUESTS.size():
			_refresh_quest_beacons(str(QuestSystemScript.QUESTS[quests.current_index]["kill_type"]))



func _on_target_changed(target: Node) -> void:
	if hud and hud.has_method("show_target"):
		hud.show_target(target)


func _build_camp_and_portal() -> void:
	# 谷内传送门（靠近营地方向）
	portal_to_camp = PortalScript.new()
	portal_to_camp.name = "PortalToCamp"
	portal_to_camp.set("target_world", "camp")
	portal_to_camp.position = Vector3(-6, _ground_y(-6, 6), 6)
	add_child(portal_to_camp)
	portal_to_camp.connect("portal_used", _on_portal_used)

	# 营地世界（默认隐藏）
	camp_world = Node3D.new()
	camp_world.name = "CampWorld"
	camp_world.visible = false
	add_child(camp_world)
	var camp := Node3D.new()
	camp.set_script(CampWorldScript)
	camp_world.add_child(camp)
	camp.call("build", player, quests, _on_portal_used)

	# 任务状态：完成任务4后解锁传送门
	if quests:
		quests.quest_completed.connect(func(id: int, _e: int) -> void:
			if id >= GB.PORTAL_UNLOCK_QUEST_ID:
				portal_to_camp.set_locked(false)
				if hud.has_method("show_toast"):
					hud.show_toast("营地传送门已解锁！", Color(0.4, 0.8, 1))
		)
		quests.npc_quest_state_changed.connect(_update_npc_mark)

	_set_input_npc()


func _set_input_npc() -> void:
	# F 键对话
	if not InputMap.has_action("interact"):
		InputMap.add_action("interact")
		var ev := InputEventKey.new()
		ev.keycode = KEY_F
		InputMap.action_add_event("interact", ev)


func _process(_delta: float) -> void:
	if current_world != "camp":
		return
	if Input.is_action_just_pressed("interact"):
		_try_talk_npc()


func _try_talk_npc() -> void:
	if quests == null or camp_world == null:
		return
	var npc: Node3D = null
	for c in camp_world.get_children():
		var n := c.get_node_or_null("QuestNPC") if c is Node else null
		if n:
			npc = n
			break
	# CampWorld script builds QuestNPC as child of camp root
	if npc == null:
		npc = camp_world.get_node_or_null("QuestNPC")
	if npc == null:
		# search deeper
		npc = _find_node_name(camp_world, "QuestNPC")
	if npc == null or player == null:
		return
	if player.global_position.distance_to(npc.global_position) > 4.0:
		if hud.has_method("show_toast"):
			hud.show_toast("靠近NPC再对话", Color(1, 1, 1, 0.7))
		return
	if quests.can_turn_in():
		if quests.npc_turn_in() and hud.has_method("show_toast"):
			hud.show_toast("任务完成，获得奖励！", Color(0.4, 1, 0.5))
	elif quests.needs_npc():
		if quests.npc_accept() and hud.has_method("show_toast"):
			hud.show_toast("已接取任务：" + str(quests.current_quest().get("name", "")), Color(1, 0.9, 0.3))
	else:
		if hud.has_method("show_toast"):
			hud.show_toast("暂无新任务，继续冒险吧", Color(1, 1, 1, 0.7))
	_update_npc_mark()


func _find_node_name(root: Node, nname: String) -> Node:
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name == nname:
			return n
		for c in n.get_children():
			stack.push_back(c)
	return null


func _update_npc_mark() -> void:
	if camp_world == null or quests == null:
		return
	var npc := _find_node_name(camp_world, "QuestNPC")
	if npc == null:
		return
	var mark: Label3D = npc.get_node_or_null("NpcMark")
	if mark == null:
		return
	if quests.finished:
		mark.text = ""
	elif quests.can_turn_in():
		mark.text = "?"
		mark.modulate = Color(0.4, 1, 0.5)
	elif quests.needs_npc():
		mark.text = "!"
		mark.modulate = Color(1, 0.85, 0.2)
	else:
		mark.text = ""


func _on_portal_used(target: String) -> void:
	_switch_world(target)


func _switch_world(world: String) -> void:
	if world == current_world or player == null:
		return
	if world == "camp":
		current_world = "camp"
		# 隐藏山谷内容（地形仍可保留，只藏怪和传送门）
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Node3D:
				(e as Node3D).visible = false
				(e as Node3D).collision_layer = 0
		if portal_to_camp:
			portal_to_camp.visible = false
		camp_world.visible = true
		player.global_position = Vector3(0, 0.2, 4)
		player.clear_target()
		if hud.has_method("show_toast"):
			hud.show_toast("抵达部落营地", Color(0.5, 0.9, 1))
	elif world == "valley":
		current_world = "valley"
		camp_world.visible = false
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Node3D:
				(e as Node3D).visible = true
				if e.has_method("is_alive") and e.is_alive():
					(e as Node3D).collision_layer = 4
		if portal_to_camp:
			portal_to_camp.visible = true
		player.global_position = Vector3(-6, _ground_y(-6, 4), 4)
		if hud.has_method("show_toast"):
			hud.show_toast("返回杜隆塔尔山谷", Color(0.9, 0.85, 0.5))
