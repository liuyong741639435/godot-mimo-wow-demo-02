class_name EnemyBase
extends CharacterBody3D
const GB := preload("res://wow/data/GameBalance.gd")
const VFX := preload("res://wow/scripts/systems/VfxLibrary.gd")
const AUDIO := preload("res://wow/scripts/systems/AudioManager.gd")
const DMGNUM := preload("res://wow/scripts/systems/DamageNumbers.gd")
const WeaponData := preload("res://wow/data/WeaponData.gd")
## Full enemy: patrol, aggro, attack, leash, respawn. Geometry built by factory.

signal died_signal(enemy: EnemyBase, killer: Node)

enum State { PATROL, CHASE, ATTACK, RETURN, DEAD }

@export var type_id := "boar"
var is_elite := false

var display_name := "怪物"
var creature_type := "野兽"
var level := 1
var max_hp := 60.0
var hp := 60.0
var attack_power := 5.0
var exp_reward := 15
var body_color := Color(0.5, 0.35, 0.22)

var state: State = State.PATROL
var target_player: Node3D = null
var aggro := false
var detect_range := 5.0
var selected := false

## 全局同时进战数量限制
static var _active_aggro_count := 0

var _home: Vector3
var _waypoints: Array[Vector3] = []
var _wp_index := 0
var _attack_cd := 0.0
var _respawn_t := 0.0
var _corpse_t := 0.0
var _stun_t := 0.0
var _anim_t := 0.0
var _select_ring: MeshInstance3D
var _last_attacker: Node = null

@onready var label: Label3D = $Label3D
@onready var hp_bar_bg: MeshInstance3D = $HpBar
@onready var hp_bar_fill: MeshInstance3D = $HpBar/Fill
@onready var visual: Node3D = $Visual


func configure(type: String, elite: bool = false) -> void:
	type_id = type
	is_elite = elite
	var data: Dictionary = GB.ENEMY_TYPES.get(type, GB.ENEMY_TYPES["boar"])
	display_name = data["display_name"]
	creature_type = data["creature_type"]
	level = data["level"]
	max_hp = data["max_hp"]
	hp = max_hp
	attack_power = data["attack"]
	exp_reward = data["exp"]
	body_color = data["body_color"]
	detect_range = float(data.get("detect_range", GB.ENEMY_DETECT_RANGE))
	if elite:
		display_name = str(GB.ELITE_NAMES.get(type, "精英·" + display_name))
		level = mini(level + 1, 5)
		max_hp = max_hp * GB.ELITE_HP_MULT
		hp = max_hp
		attack_power = attack_power * GB.ELITE_ATK_MULT
		exp_reward = int(exp_reward * GB.ELITE_EXP_MULT)
		detect_range = detect_range + 1.5
		body_color = body_color.lightened(0.12)
		scale = Vector3.ONE * GB.ELITE_SCALE


func set_elite(on: bool) -> void:
	configure(type_id, on)


func _ready() -> void:
	add_to_group("enemies")
	_home = global_position
	_waypoints = [
		_home,
		_home + Vector3(3, 0, 1.5),
		_home + Vector3(-1.5, 0, 3),
		_home + Vector3(1.5, 0, -2),
	]
	_build_select_ring()
	_apply_elite_look()
	if label:
		_refresh_label()
	_update_hp_bar()


func _refresh_label() -> void:
	if label == null:
		return
	if is_elite:
		label.text = "%s Lv%d" % [display_name, level]
		label.modulate = Color(1.0, 0.82, 0.15)
		label.font_size = 24
		label.outline_size = 8
	else:
		label.text = "%s Lv%d" % [display_name, level]
		label.modulate = Color.WHITE
		label.font_size = 20
		label.outline_size = 5


func _apply_elite_look() -> void:
	if not is_elite:
		return
	# 金色选中环（精英常亮更醒目）
	if _select_ring:
		var mat := _select_ring.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(1.0, 0.55, 0.05)
			mat.emission = Color(1.0, 0.5, 0.05)
			mat.emission_energy_multiplier = 2.5
		_select_ring.visible = true
	# 头顶小金标
	if get_node_or_null("EliteCrown") == null:
		var crown := MeshInstance3D.new()
		crown.name = "EliteCrown"
		var cm := BoxMesh.new()
		cm.size = Vector3(0.35, 0.08, 0.35)
		crown.mesh = cm
		crown.position = Vector3(0, 1.95, 0)
		var cmat := StandardMaterial3D.new()
		cmat.albedo_color = Color(1.0, 0.75, 0.1)
		cmat.emission_enabled = true
		cmat.emission = Color(1.0, 0.7, 0.1)
		cmat.emission_energy_multiplier = 1.5
		crown.material_override = cmat
		add_child(crown)
	# 身体略偏金
	if visual:
		for c in visual.get_children():
			if c is MeshInstance3D:
				var m := c.material_override as StandardMaterial3D
				if m:
					m.albedo_color = m.albedo_color.lerp(Color(0.85, 0.65, 0.25), 0.18)


func flash_hit() -> void:
	if visual == null:
		return
	for c in visual.get_children():
		if c is MeshInstance3D:
			var mat := c.material_override as StandardMaterial3D
			if mat == null:
				continue
			var old: Color = mat.albedo_color
			mat.albedo_color = Color(1.0, 0.25, 0.2)
			get_tree().create_timer(0.1).timeout.connect(func() -> void:
				if is_instance_valid(mat):
					mat.albedo_color = old
			)


func _build_select_ring() -> void:
	_select_ring = MeshInstance3D.new()
	_select_ring.name = "SelectRing"
	var torus := TorusMesh.new()
	torus.inner_radius = 0.55
	torus.outer_radius = 0.7
	torus.rings = 24
	torus.ring_segments = 8
	_select_ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.15)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.1)
	mat.emission_energy_multiplier = 1.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.85
	_select_ring.material_override = mat
	_select_ring.position = Vector3(0, 0.05, 0)
	_select_ring.visible = false
	add_child(_select_ring)


func set_selected(on: bool) -> void:
	selected = on
	if _select_ring:
		_select_ring.visible = on and state != State.DEAD


func _try_detect_player() -> void:
	if target_player == null or not is_instance_valid(target_player):
		target_player = _find_player()
	if target_player == null:
		return
	if _is_player_dead():
		return
	# 同时进战数量限制（前期防围殴）
	if _active_aggro_count >= GB.ENEMY_MAX_SIMULTANEOUS_AGGRO and not aggro:
		return
	if global_position.distance_to(target_player.global_position) <= detect_range:
		_enter_aggro()


func _enter_aggro() -> void:
	if aggro:
		return
	aggro = true
	_active_aggro_count += 1
	state = State.CHASE
	if target_player and target_player.get("stats"):
		target_player.stats.enter_combat()


func _clear_aggro() -> void:
	if aggro:
		_active_aggro_count = maxi(_active_aggro_count - 1, 0)
	aggro = false
	target_player = null


func _exit_tree() -> void:
	if aggro:
		_active_aggro_count = maxi(_active_aggro_count - 1, 0)
		aggro = false



func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		_respawn_t -= delta
		_corpse_t -= delta
		if _corpse_t <= 0.0 and visual:
			visual.visible = false
		if _respawn_t <= 0.0:
			_revive()
		return

	_anim_t += delta
	_animate()
	_update_hp_bar()
	_billboard_ui()
	if selected and _select_ring:
		_select_ring.rotation.y += delta * 2.5
		var pulse := 1.0 + sin(_anim_t * 6.0) * 0.06
		_select_ring.scale = Vector3(pulse, 1.0, pulse)

	if _stun_t > 0.0:
		_stun_t -= delta
		velocity.x = 0
		velocity.z = 0
		if not is_on_floor():
			velocity.y -= 18.0 * delta
		move_and_slide()
		return

	_attack_cd = maxf(_attack_cd - delta, 0.0)

	match state:
		State.PATROL:
			_do_patrol(delta)
		State.CHASE:
			_do_chase(delta)
		State.ATTACK:
			_do_attack(delta)
		State.RETURN:
			_do_return(delta)

	# gravity
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0
	move_and_slide()


func _do_patrol(delta: float) -> void:
	_try_detect_player()
	if aggro:
		return
	if _waypoints.is_empty():
		velocity.x = 0
		velocity.z = 0
		return
	var wp: Vector3 = _waypoints[_wp_index]
	var to := wp - global_position
	to.y = 0
	if to.length() < 0.6:
		_wp_index = (_wp_index + 1) % _waypoints.size()
		return
	to = to.normalized()
	velocity.x = to.x * GB.ENEMY_PATROL_SPEED
	velocity.z = to.z * GB.ENEMY_PATROL_SPEED
	_face(to)


func _do_chase(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		_clear_aggro()
		return
	if _is_player_dead():
		_clear_aggro()
		return
	var dist := global_position.distance_to(target_player.global_position)
	if dist > GB.ENEMY_LEASH_RANGE:
		_clear_aggro()
		state = State.RETURN
		return
	if dist <= GB.ENEMY_ATTACK_RANGE:
		state = State.ATTACK
		velocity.x = 0
		velocity.z = 0
		return
	var to := target_player.global_position - global_position
	to.y = 0
	to = to.normalized()
	velocity.x = to.x * GB.ENEMY_CHASE_SPEED
	velocity.z = to.z * GB.ENEMY_CHASE_SPEED
	_face(to)


func _do_attack(_delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player) or _is_player_dead():
		_clear_aggro()
		state = State.RETURN
		return
	var dist := global_position.distance_to(target_player.global_position)
	if dist > GB.ENEMY_ATTACK_RANGE + 0.4:
		state = State.CHASE
		return
	var to := target_player.global_position - global_position
	to.y = 0
	if to.length() > 0.05:
		_face(to.normalized())
	velocity.x = 0
	velocity.z = 0
	if _attack_cd <= 0.0:
		_attack_cd = GB.ENEMY_ATTACK_INTERVAL
		AUDIO.play(self, "slash", -14.0)
		# damage after short windup
		get_tree().create_timer(0.25).timeout.connect(func() -> void:
			if state != State.ATTACK and state != State.CHASE:
				return
			if target_player and is_instance_valid(target_player):
				if global_position.distance_to(target_player.global_position) <= GB.ENEMY_ATTACK_RANGE + 0.5:
					if target_player.has_method("take_damage"):
						target_player.take_damage(attack_power, self)
		)


func _do_return(_delta: float) -> void:
	var to := _home - global_position
	to.y = 0
	if to.length() < 0.5:
		state = State.PATROL
		velocity.x = 0
		velocity.z = 0
		hp = max_hp
		_update_hp_bar()
		return
	to = to.normalized()
	velocity.x = to.x * GB.ENEMY_PATROL_SPEED
	velocity.z = to.z * GB.ENEMY_PATROL_SPEED
	_face(to)
	# leash regen walk-back heals fully on arrive only


func _find_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		return players[0]
	var p := get_tree().get_first_node_in_group("player")
	return p as Node3D


func _is_player_dead() -> bool:
	if target_player == null:
		return true
	if target_player.has_method("stats") and target_player.stats and target_player.stats.is_dead():
		return true
	return false


func is_alive() -> bool:
	return state != State.DEAD


func is_aggro() -> bool:
	return aggro and state != State.DEAD


func take_damage(amount: float, from: Node = null) -> void:
	if state == State.DEAD:
		return
	hp = maxf(hp - amount, 0.0)
	if from:
		_last_attacker = from
	_update_hp_bar()
	flash_hit()
	if from and from.get("stats"):
		from.stats.enter_combat()
	# 被玩家打的怪必进战（不受同时进战名额限制，否则打不动）
	if from is Node3D:
		target_player = from
		if not aggro:
			aggro = true
			_active_aggro_count += 1
		if state == State.PATROL or state == State.RETURN:
			state = State.CHASE
	if hp <= 0.0:
		_die(from if from else _last_attacker)


func apply_stun(t: float) -> void:
	_stun_t = maxf(_stun_t, t)


func apply_dot(damage_per_tick: float, ticks: int, interval: float) -> void:
	_apply_dot_serial(damage_per_tick, ticks, interval)


func _apply_dot_serial(damage_per_tick: float, ticks: int, interval: float) -> void:
	if ticks <= 0:
		return
	get_tree().create_timer(interval).timeout.connect(func() -> void:
		if state == State.DEAD:
			return
		hp = maxf(hp - damage_per_tick, 0.0)
		_update_hp_bar()
		if get_parent():
			DMGNUM.spawn(get_parent(), global_position + Vector3(0, 1.4, 0), str(int(round(damage_per_tick))), Color(0.7, 0.2, 0.55))
		if hp <= 0.0:
			_die(_last_attacker)
		else:
			_apply_dot_serial(damage_per_tick, ticks - 1, interval)
	)


func _die(killer: Node = null) -> void:
	if killer == null:
		killer = _last_attacker
	if aggro:
		_active_aggro_count = maxi(_active_aggro_count - 1, 0)
	state = State.DEAD
	aggro = false
	set_selected(false)
	_respawn_t = GB.ENEMY_RESPAWN_TIME
	_corpse_t = GB.ENEMY_CORPSE_TIME
	velocity = Vector3.ZERO
	VFX.hit_spark(get_parent() if get_parent() else self, global_position)
	AUDIO.play(get_parent() if get_parent() else self, "enemy_die")
	if killer and killer.get("stats") and killer.stats:
		killer.stats.gain_exp(exp_reward)
		if killer.has_method("clear_target") and killer.get("current_target") == self:
			killer.clear_target()
		if get_parent():
			DMGNUM.spawn(get_parent(), global_position + Vector3(0, 1.8, 0), "+%d EXP" % exp_reward, Color(0.35, 1.0, 0.45))
		# 装备掉落（进背包，非自动装备）
		var drop: Dictionary = WeaponData.roll_drop(type_id, is_elite)
		if not drop.is_empty() and killer.get("inventory"):
			killer.inventory.add_weapon_drop(drop)
			var qname: String = WeaponData.quality_name(str(drop.get("quality", "common")))
			if get_tree().current_scene and get_tree().current_scene.has_node("HUD"):
				var hud = get_tree().current_scene.get_node("HUD")
				if hud.has_method("show_toast"):
					hud.show_toast("掉落：%s  %s" % [qname, str(drop.get("name", ""))], WeaponData.quality_color(str(drop.get("quality", "common"))))
			AUDIO.play(get_parent() if get_parent() else self, "quest")
	died_signal.emit(self, killer)
	if hp_bar_bg:
		hp_bar_bg.visible = false
	if label:
		label.visible = false
	collision_layer = 0
	collision_mask = 0


func _revive() -> void:
	state = State.PATROL
	hp = max_hp
	global_position = _home
	velocity = Vector3.ZERO
	_stun_t = 0
	_clear_aggro()
	if visual:
		visual.visible = true
	if label:
		label.visible = true
		label.text = "%s Lv%d" % [display_name, level]
	if hp_bar_bg:
		hp_bar_bg.visible = true
	_update_hp_bar()
	collision_layer = 4
	collision_mask = 1


func _update_hp_bar() -> void:
	if hp_bar_fill == null:
		return
	var ratio := clampf(hp / max_hp, 0.0, 1.0)
	hp_bar_fill.scale.x = maxf(ratio, 0.01)
	hp_bar_fill.position.x = -(1.0 - ratio) * 0.45


func _billboard_ui() -> void:
	var cam := get_viewport().get_camera_3d() if get_viewport() else null
	if cam == null:
		return
	if hp_bar_bg and is_instance_valid(hp_bar_bg):
		var to_cam := cam.global_position - hp_bar_bg.global_position
		to_cam.y = 0.0
		if to_cam.length_squared() > 0.0001:
			hp_bar_bg.look_at(hp_bar_bg.global_position + to_cam.normalized(), Vector3.UP)
	if get_node_or_null("EliteCrown"):
		var crown: Node3D = get_node("EliteCrown")
		var tc := cam.global_position - crown.global_position
		tc.y = 0.0
		if tc.length_squared() > 0.0001:
			crown.look_at(crown.global_position + tc.normalized(), Vector3.UP)


func _face(dir: Vector3) -> void:
	if visual and dir.length() > 0.01:
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), 8.0 * get_physics_process_delta_time())


func _animate() -> void:
	if visual == null:
		return
	match state:
		State.PATROL:
			visual.position.y = absf(sin(_anim_t * 4.0)) * 0.04
		State.CHASE:
			visual.position.y = absf(sin(_anim_t * 10.0)) * 0.08
		State.ATTACK:
			visual.position.y = absf(sin(_anim_t * 12.0)) * 0.05
		State.RETURN:
			visual.position.y = absf(sin(_anim_t * 4.0)) * 0.04
		State.DEAD:
			visual.rotation.z = lerp_angle(visual.rotation.z, 1.3, 0.1)
