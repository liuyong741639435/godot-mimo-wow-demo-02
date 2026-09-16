class_name Player
extends CharacterBody3D
const GB := preload("res://wow/data/GameBalance.gd")
const VFX := preload("res://wow/scripts/systems/VfxLibrary.gd")
const AUDIO := preload("res://wow/scripts/systems/AudioManager.gd")
const DMGNUM := preload("res://wow/scripts/systems/DamageNumbers.gd")
const WD := preload("res://wow/data/WeaponData.gd")
const WEAPON_BUILDER := preload("res://wow/scripts/systems/WeaponBuilder.gd")
## Orc warrior controller (sword/axe, dual-world)

signal target_changed(target: Node)
signal player_died
signal player_respawned
signal weapon_changed(weapon_id: String, display_name: String)

var equipped_weapon := "none"
var weapon_bonus_atk := 0.0
var _is_sword := false
var _dust_cd := 0.0

@onready var stats: PlayerStats = $PlayerStats
@onready var skills: SkillController = $SkillController
@onready var animator: PlayerAnimator = $PlayerAnimator
@onready var visual: Node3D = $Visual
@onready var camera: Camera3D = $Camera3D
@onready var name_label: Label3D = $NameLabel

var current_target: Node3D = null
var attack_timer: float = 0.0
var charge_timer: float = 0.0
var charge_dir: Vector3 = Vector3.ZERO
var is_charging: bool = false
var _respawn_origin: Vector3

var _cam_yaw: float = 0.0
var _cam_pitch: float = 0.32
var _cam_dist: float = 8.0
var _mouse_captured: bool = false


func _ready() -> void:
	add_to_group("player")
	_respawn_origin = global_position
	skills.setup(self, stats)
	stats.died.connect(_on_died)
	if name_label:
		name_label.text = "兽人战士 Lv1"
	stats.level_up.connect(func(lv: int) -> void:
		if name_label:
			name_label.text = "兽人战士 Lv%d" % lv
		VFX.level_up(get_parent(), global_position)
		AUDIO.play(get_parent(), "levelup")
	)
	stats.exp_changed.connect(func(cur: int, need: int, lv: int) -> void:
		# 调试/反馈：经验变化时轻提示
		if need > 0 and cur < need and get_parent():
			pass
	)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_wire_animator()
	equip_weapon("none")


func equip_weapon(weapon_id: String) -> void:
	var w: Dictionary = WD.get_weapon(weapon_id)
	equipped_weapon = weapon_id
	weapon_bonus_atk = float(w.get("atk_bonus", 0.0))
	_is_sword = weapon_id != "none"
	var weapon_root: Node3D = null
	if visual:
		weapon_root = visual.get_node_or_null("OrcVisual/Torso/ArmR/Weapon")
	if weapon_root:
		if _is_sword:
			WEAPON_BUILDER.build_sword(weapon_root, weapon_id)
		else:
			WEAPON_BUILDER.build_axe(weapon_root)
	if animator:
		animator.is_sword = _is_sword
	weapon_changed.emit(weapon_id, str(w.get("display_name", "武器")))


func get_total_attack() -> float:
	return stats.get_base_attack() + weapon_bonus_atk


func _wvfx() -> Color:
	return Color(WD.get_weapon(equipped_weapon).get("vfx_color", Color(1, 0.95, 0.7)))


func _wire_animator() -> void:
	if animator == null or visual == null:
		return
	var base := visual.get_node_or_null("OrcVisual")
	if base == null:
		return
	var nodes := {
		"torso_path": base.get_node_or_null("Torso"),
		"head_path": base.get_node_or_null("Torso/Head"),
		"arm_l_path": base.get_node_or_null("Torso/ArmL"),
		"arm_r_path": base.get_node_or_null("Torso/ArmR"),
		"leg_l_path": base.get_node_or_null("LegL"),
		"leg_r_path": base.get_node_or_null("LegR"),
		"weapon_path": base.get_node_or_null("Torso/ArmR/Weapon"),
	}
	for key in nodes:
		var n: Node = nodes[key]
		if n:
			animator.set(key, n.get_path())
	animator._ready()
	animator.capture_base_positions()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_try_click_target()


func _input(event: InputEvent) -> void:
	# 镜头必须走 _input，避免被 Control/面板抢事件导致上下转不动
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				_mouse_captured = true
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
				get_viewport().set_input_as_handled()
			else:
				_mouse_captured = false
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseMotion and _mouse_captured:
		var mm := event as InputEventMouseMotion
		_cam_yaw -= mm.relative.x * 0.006
		# 上下：鼠标向上抬镜头压低视角，向下放镜头抬高；范围放宽
		_cam_pitch = clampf(_cam_pitch + mm.relative.y * 0.006, -0.35, 1.25)
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_TAB:
			_cycle_target()
		elif event.keycode == KEY_ESCAPE:
			_mouse_captured = false
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _physics_process(delta: float) -> void:
	if stats.is_dead():
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= GB.PLAYER_GRAVITY * delta
		move_and_slide()
		return

	_update_camera()
	_update_skills_input()
	_update_charge(delta)

	if not is_on_floor():
		velocity.y -= GB.PLAYER_GRAVITY * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = GB.PLAYER_JUMP_VELOCITY
		AUDIO.play(self, "jump", -12.0)

	var input_vec := Vector2.ZERO
	# get_axis: first action = -1, second = +1
	# W(move_forward)=-1, S=+1; A(move_left)=-1, D=+1
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_forward", "move_back")
	input_vec = input_vec.limit_length(1.0)

	# Camera-relative: use real camera look direction (screen forward / right)
	var cam_fwd := Vector3.ZERO
	var cam_right := Vector3.ZERO
	if camera:
		cam_fwd = -camera.global_transform.basis.z
		cam_right = camera.global_transform.basis.x
	else:
		cam_fwd = Basis(Vector3.UP, _cam_yaw) * Vector3(0, 0, -1)
		cam_right = Basis(Vector3.UP, _cam_yaw) * Vector3(1, 0, 0)
	cam_fwd.y = 0.0
	cam_right.y = 0.0
	cam_fwd = cam_fwd.normalized()
	cam_right = cam_right.normalized()
	# W (-1) -> forward; D (+1) -> right
	var dir := cam_fwd * (-input_vec.y) + cam_right * input_vec.x
	if dir.length() > 0.01:
		dir = dir.normalized()

	# 朝向：优先打目标；右键锁定镜头朝向（可后退输出）；否则跟移动方向
	if visual:
		var face_yaw: float = visual.rotation.y
		var have_face := false
		if current_target and is_instance_valid(current_target) and current_target.has_method("is_alive") and current_target.is_alive():
			if global_position.distance_to(current_target.global_position) <= GB.PLAYER_MELEE_RANGE + 0.6:
				var to_t := current_target.global_position - global_position
				if to_t.length_squared() > 0.0001:
					face_yaw = atan2(to_t.x, to_t.z)
					have_face = true
		if not have_face and _mouse_captured:
			# 按住右键：身体始终朝镜头前方，便于边退边打
			face_yaw = atan2(cam_fwd.x, cam_fwd.z)
			have_face = true
		if not have_face and dir.length() > 0.01:
			face_yaw = atan2(dir.x, dir.z)
		if have_face or dir.length() > 0.01 or _mouse_captured or (current_target != null):
			visual.rotation.y = lerp_angle(visual.rotation.y, face_yaw, 14.0 * delta)

	if is_charging:
		velocity.x = charge_dir.x * 18.0
		velocity.z = charge_dir.z * 18.0
	else:
		velocity.x = dir.x * GB.PLAYER_MOVE_SPEED
		velocity.z = dir.z * GB.PLAYER_MOVE_SPEED

	move_and_slide()

	if animator:
		animator.set_locomotion(is_on_floor(), dir.length() > 0.1, velocity.y)

	# 跑动沙尘
	_footstep_dust(delta, dir)

	_tick_auto_attack(delta)
	_tick_combat_proximity(delta)


func _footstep_dust(delta: float, dir: Vector3) -> void:
	_dust_cd = maxf(_dust_cd - delta, 0.0)
	if not is_on_floor() or dir.length() < 0.2 or _dust_cd > 0.0:
		return
	_dust_cd = 0.18
	var parent := get_parent()
	if parent:
		for i in range(3):
			var p: Node3D = VFX.ParticleScript.new()
			parent.add_child(p)
			p.global_position = global_position + Vector3(randf_range(-0.2, 0.2), 0.08, randf_range(-0.2, 0.2))
			p.setup(Color(0.75, 0.65, 0.45), randf_range(0.04, 0.08))
			p.dir = Vector3(randf_range(-0.3, 0.3), randf_range(0.4, 1.0), randf_range(-0.3, 0.3)).normalized()
			p.speed = 0.8
			p.life = 0.35



func _update_camera() -> void:
	if camera == null:
		return
	var pivot_pos := global_position + Vector3(0, 1.4, 0)
	var basis := Basis.from_euler(Vector3(_cam_pitch, _cam_yaw, 0.0))
	var offset := basis * Vector3(0, 0, _cam_dist)
	camera.global_position = pivot_pos - offset
	camera.look_at(pivot_pos, Vector3.UP)


func _try_click_target() -> void:
	var space := get_world_3d().direct_space_state
	if camera == null or space == null:
		return
	var mouse := get_viewport().get_mouse_position()
	var from := camera.project_ray_origin(mouse)
	var dir := camera.project_ray_normal(mouse)
	var query := PhysicsRayQueryParameters3D.create(from, from + dir * 200.0)
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	var collider = hit.get("collider")
	if collider is Node3D and collider.is_in_group("enemies"):
		set_target(collider)


func set_target(t: Node3D) -> void:
	if current_target == t:
		return
	if current_target and is_instance_valid(current_target) and current_target.has_method("set_selected"):
		current_target.set_selected(false)
	current_target = t
	if current_target and current_target.has_method("set_selected"):
		current_target.set_selected(true)
	target_changed.emit(t)


func clear_target() -> void:
	if current_target == null:
		return
	if is_instance_valid(current_target) and current_target.has_method("set_selected"):
		current_target.set_selected(false)
	current_target = null
	target_changed.emit(null)


func _update_skills_input() -> void:
	if Input.is_action_just_pressed("skill_1"):
		if skills.try_heroic():
			animator.play_action(PlayerAnimator.AnimState.ATTACK, 0.4)
			AUDIO.play(get_parent(), "heavy")
			_deal_skill_damage(GB.HEROIC_DAMAGE_MULT)
	elif Input.is_action_just_pressed("skill_2"):
		if skills.try_charge():
			_start_charge()
	elif Input.is_action_just_pressed("skill_3"):
		if skills.try_intercept():
			_start_intercept()
	elif Input.is_action_just_pressed("skill_4"):
		if skills.try_whirlwind():
			animator.play_action(PlayerAnimator.AnimState.CAST, 0.6)
			_deal_whirlwind()
	elif Input.is_action_just_pressed("skill_5"):
		if skills.try_potion():
			animator.play_action(PlayerAnimator.AnimState.CAST, 0.35)
			VFX.heal_spark(get_parent(), global_position)
			AUDIO.play(get_parent(), "potion")
			DMGNUM.heal_number(get_parent(), global_position, GB.POTION_HEAL_AMOUNT)
	elif Input.is_action_just_pressed("skill_6"):
		if skills.try_rend():
			animator.play_action(PlayerAnimator.AnimState.ATTACK, 0.35)
			AUDIO.play(get_parent(), "slash")
			_deal_skill_damage(GB.REND_DAMAGE_MULT, true)
	elif Input.is_action_just_pressed("skill_7"):
		if skills.try_thunder():
			animator.play_action(PlayerAnimator.AnimState.CAST, 0.5)
			AUDIO.play(get_parent(), "heavy")
			_deal_aoe(GB.THUNDER_RADIUS, GB.THUNDER_DAMAGE_MULT)
	elif Input.is_action_just_pressed("skill_8"):
		if skills.try_execute():
			animator.play_action(PlayerAnimator.AnimState.ATTACK, 0.4)
			AUDIO.play(get_parent(), "heavy")
			_deal_skill_damage(GB.EXECUTE_DAMAGE_MULT)
	elif Input.is_action_just_pressed("skill_9"):
		if skills.try_mortal():
			animator.play_action(PlayerAnimator.AnimState.ATTACK, 0.45)
			AUDIO.play(get_parent(), "heavy")
			_deal_skill_damage(GB.MORTAL_DAMAGE_MULT)
	elif Input.is_action_just_pressed("skill_10"):
		if skills.try_bladestorm():
			animator.play_action(PlayerAnimator.AnimState.CAST, 0.8)
			AUDIO.play(get_parent(), "whirl")
			_deal_bladestorm()


func _start_charge() -> void:
	animator.play_action(PlayerAnimator.AnimState.CAST, 0.45)
	is_charging = true
	charge_timer = 0.35
	VFX.charge_trail(get_parent(), global_position)
	AUDIO.play(get_parent(), "charge")
	if current_target and is_instance_valid(current_target):
		charge_dir = current_target.global_position - global_position
		charge_dir.y = 0.0
		charge_dir = charge_dir.normalized() if charge_dir.length() > 0.05 else Vector3.FORWARD
	else:
		charge_dir = -visual.global_transform.basis.z
		charge_dir.y = 0.0
		charge_dir = charge_dir.normalized()
	if visual:
		visual.rotation.y = atan2(charge_dir.x, charge_dir.z)


func _start_intercept() -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	animator.play_action(PlayerAnimator.AnimState.CAST, 0.4)
	is_charging = true
	charge_timer = 0.3
	VFX.charge_trail(get_parent(), global_position)
	charge_dir = current_target.global_position - global_position
	charge_dir.y = 0.0
	charge_dir = charge_dir.normalized() if charge_dir.length() > 0.05 else Vector3.FORWARD
	if visual:
		visual.rotation.y = atan2(charge_dir.x, charge_dir.z)


func _update_charge(_delta: float) -> void:
	if not is_charging:
		return
	charge_timer -= _delta
	if current_target and is_instance_valid(current_target):
		var d := global_position.distance_to(current_target.global_position)
		if d <= GB.PLAYER_MELEE_RANGE:
			if stats.in_combat and stats.level >= GB.INTERCEPT_UNLOCK_LEVEL:
				_apply_damage_to(current_target, get_total_attack() * GB.INTERCEPT_DAMAGE_MULT)
			else:
				_apply_damage_to(current_target, GB.CHARGE_DAMAGE)
				if current_target.has_method("apply_stun"):
					current_target.apply_stun(GB.CHARGE_STUN_TIME)
				stats.add_rage(GB.PLAYER_CHARGE_RAGE_GAIN)
			stats.enter_combat()
			is_charging = false
	if charge_timer <= 0.0:
		is_charging = false


func _tick_auto_attack(delta: float) -> void:
	attack_timer = maxf(attack_timer - delta, 0.0)
	if current_target == null or not is_instance_valid(current_target):
		return
	if current_target.has_method("is_alive") and not current_target.is_alive():
		clear_target()
		return
	if global_position.distance_to(current_target.global_position) > GB.PLAYER_MELEE_RANGE:
		return
	if attack_timer > 0.0:
		return
	attack_timer = GB.PLAYER_ATTACK_INTERVAL
	animator.play_action(PlayerAnimator.AnimState.ATTACK, 0.35)
	VFX.slash(get_parent(), global_position, _wvfx())
	AUDIO.play(get_parent(), "slash")
	get_tree().create_timer(0.12).timeout.connect(func() -> void:
		if current_target and is_instance_valid(current_target):
			if global_position.distance_to(current_target.global_position) <= GB.PLAYER_MELEE_RANGE + 0.4:
				_apply_damage_to(current_target, get_total_attack())
				stats.add_rage(GB.PLAYER_ATTACK_RAGE_GAIN)
				stats.enter_combat()
				VFX.hit_spark(get_parent(), current_target.global_position, _wvfx())
				AUDIO.play(get_parent(), "hit")
	)


func _deal_skill_damage(mult: float, apply_rend: bool = false) -> void:
	if current_target == null or not is_instance_valid(current_target):
		return
	get_tree().create_timer(0.1).timeout.connect(func() -> void:
		if current_target and is_instance_valid(current_target):
			if global_position.distance_to(current_target.global_position) <= GB.PLAYER_MELEE_RANGE + 0.5:
				_apply_damage_to(current_target, get_total_attack() * mult)
				stats.enter_combat()
				VFX.hit_spark(get_parent(), current_target.global_position, _wvfx())
				if apply_rend and current_target.has_method("apply_dot"):
					current_target.apply_dot(get_total_attack() * GB.REND_DOT_MULT, GB.REND_DOT_TICKS, 1.0)
	)


func _deal_aoe(radius: float, mult: float) -> void:
	VFX.whirlwind(get_parent(), global_position)
	get_tree().create_timer(0.15).timeout.connect(func() -> void:
		var hit_any := false
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Node3D and e.has_method("is_alive") and e.is_alive():
				if global_position.distance_to(e.global_position) <= radius:
					_apply_damage_to(e, get_total_attack() * mult)
					hit_any = true
		if hit_any:
			stats.enter_combat()
	)


func _deal_bladestorm() -> void:
	var pulse_i := 0
	while pulse_i < GB.BLADESTORM_PULSES:
		var delay := 0.2 * float(pulse_i)
		get_tree().create_timer(delay).timeout.connect(func() -> void:
			VFX.whirlwind(get_parent(), global_position)
			for e in get_tree().get_nodes_in_group("enemies"):
				if e is Node3D and e.has_method("is_alive") and e.is_alive():
					if global_position.distance_to(e.global_position) <= GB.BLADESTORM_RADIUS:
						_apply_damage_to(e, get_total_attack() * GB.BLADESTORM_DAMAGE_MULT)
						stats.enter_combat()
		)
		pulse_i += 1


func _deal_whirlwind() -> void:
	VFX.whirlwind(get_parent(), global_position)
	AUDIO.play(get_parent(), "whirl")
	get_tree().create_timer(0.2).timeout.connect(func() -> void:
		var hit_any := false
		for e in get_tree().get_nodes_in_group("enemies"):
			if e is Node3D and e.has_method("is_alive") and e.is_alive():
				if global_position.distance_to(e.global_position) <= GB.WHIRLWIND_RADIUS:
					_apply_damage_to(e, get_total_attack() * GB.WHIRLWIND_DAMAGE_MULT)
					VFX.hit_spark(get_parent(), e.global_position, _wvfx())
					hit_any = true
		if hit_any:
			stats.enter_combat()
	)


func _apply_damage_to(target: Node, amount: float) -> void:
	if target.has_method("take_damage"):
		target.take_damage(amount, self)
		if target is Node3D:
			DMGNUM.enemy_damage(get_parent(), (target as Node3D).global_position, amount)
			_hit_stop(0.04)


func _hit_stop(duration: float) -> void:
	Engine.time_scale = 0.25
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
		Engine.time_scale = 1.0
	)


func _tick_combat_proximity(delta: float) -> void:
	var near_threat := false
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and e.has_method("is_alive") and e.is_alive():
			if e.has_method("is_aggro") and e.is_aggro():
				if global_position.distance_to(e.global_position) <= GB.COMBAT_EXIT_DISTANCE:
					near_threat = true
					break
	if near_threat:
		stats.enter_combat()
	else:
		stats.note_combat_idle(delta)


func take_damage(amount: float, _from: Node = null) -> void:
	if stats.is_dead():
		return
	stats.take_damage(amount)
	animator.play_action(PlayerAnimator.AnimState.HIT, 0.25)
	AUDIO.play(get_parent(), "hurt")
	DMGNUM.spawn(get_parent(), global_position + Vector3(0, 1.2, 0), str(int(round(amount))), Color(1, 0.3, 0.25))


func _on_died() -> void:
	animator.force_death()
	player_died.emit()
	get_tree().create_timer(GB.PLAYER_RESPAWN_DELAY).timeout.connect(_respawn)


func _respawn() -> void:
	global_position = _respawn_origin
	velocity = Vector3.ZERO
	stats.respawn_at(_respawn_origin)
	animator.force_idle()
	clear_target()
	player_respawned.emit()


func _cycle_target() -> void:
	var enemies: Array = []
	for e in get_tree().get_nodes_in_group("enemies"):
		if e is Node3D and e.has_method("is_alive") and e.is_alive():
			enemies.append(e)
	if enemies.is_empty():
		return
	enemies.sort_custom(func(a, b) -> bool:
		return global_position.distance_squared_to(a.global_position) < global_position.distance_squared_to(b.global_position)
	)
	if current_target == null:
		set_target(enemies[0])
		return
	var idx := enemies.find(current_target)
	var next: int = (idx + 1) % enemies.size()
	set_target(enemies[next])
