class_name PlayerAnimator
extends Node
## 程序化四肢动画：待机/跑/跳/落地/挥砍/施法/受击/死亡

enum AnimState { IDLE, RUN, JUMP, FALL, LAND, ATTACK, CAST, HIT, DEATH }

@export var root_path: NodePath
@export var torso_path: NodePath
@export var head_path: NodePath
@export var arm_l_path: NodePath
@export var arm_r_path: NodePath
@export var leg_l_path: NodePath
@export var leg_r_path: NodePath
@export var weapon_path: NodePath

var state: AnimState = AnimState.IDLE
var is_sword := false
var _t: float = 0.0
var _action_t: float = 0.0
var _action_duration: float = 0.0
var _blend_from: Dictionary = {}
var _base: Dictionary = {}

var _torso: Node3D
var _head: Node3D
var _arm_l: Node3D
var _arm_r: Node3D
var _leg_l: Node3D
var _leg_r: Node3D
var _weapon: Node3D


func _ready() -> void:
	_torso = get_node_or_null(torso_path)
	_head = get_node_or_null(head_path)
	_arm_l = get_node_or_null(arm_l_path)
	_arm_r = get_node_or_null(arm_r_path)
	_leg_l = get_node_or_null(leg_l_path)
	_leg_r = get_node_or_null(leg_r_path)
	_weapon = get_node_or_null(weapon_path)
	_store_base()


func _store_base() -> void:
	for n in [_torso, _head, _arm_l, _arm_r, _leg_l, _leg_r, _weapon]:
		if n:
			_base[n] = n.rotation


func play_action(name: AnimState, duration: float) -> void:
	state = name
	_action_t = 0.0
	_action_duration = maxf(duration, 0.05)


func set_locomotion(on_ground: bool, moving: bool, velocity_y: float) -> void:
	if state in [AnimState.ATTACK, AnimState.CAST, AnimState.HIT, AnimState.DEATH]:
		return
	if not on_ground:
		state = AnimState.JUMP if velocity_y > 0.5 else AnimState.FALL
	elif state in [AnimState.JUMP, AnimState.FALL]:
		play_action(AnimState.LAND, 0.18)
	elif state == AnimState.LAND and _action_t >= _action_duration:
		state = AnimState.RUN if moving else AnimState.IDLE
	elif state != AnimState.LAND:
		state = AnimState.RUN if moving else AnimState.IDLE


func force_death() -> void:
	play_action(AnimState.DEATH, 999.0)


func force_idle() -> void:
	state = AnimState.IDLE


func _process(delta: float) -> void:
	_t += delta
	if _action_duration > 0.0 and state in [AnimState.ATTACK, AnimState.CAST, AnimState.HIT, AnimState.LAND]:
		_action_t += delta
		if _action_t >= _action_duration and state != AnimState.DEATH:
			_action_duration = 0.0
			state = AnimState.IDLE
	_apply(delta)


func _apply(_delta: float) -> void:
	var idle_sway := sin(_t * 2.0) * 0.04
	var breathe := sin(_t * 2.2) * 0.03
	match state:
		AnimState.IDLE:
			_reset_parts()
			if _arm_l:
				_arm_l.rotation.x = -0.15 + idle_sway
			if _arm_r:
				_arm_r.rotation.x = -0.1 - idle_sway
			if _torso:
				_torso.rotation.x = breathe
			if _head:
				_head.rotation.y = sin(_t * 0.7) * 0.15
		AnimState.RUN:
			_reset_parts()
			var swing := sin(_t * 10.0) * 0.7
			if _leg_l:
				_leg_l.rotation.x = swing
			if _leg_r:
				_leg_r.rotation.x = -swing
			if _arm_l:
				_arm_l.rotation.x = -swing * 0.6
			if _arm_r:
				_arm_r.rotation.x = swing * 0.5
			if _torso:
				_torso.rotation.x = 0.12
		AnimState.JUMP:
			_reset_parts()
			if _leg_l:
				_leg_l.rotation.x = 0.5
			if _leg_r:
				_leg_r.rotation.x = 0.2
			if _arm_l:
				_arm_l.rotation.x = -0.6
			if _arm_r:
				_arm_r.rotation.x = -0.8
		AnimState.FALL:
			_reset_parts()
			if _leg_l:
				_leg_l.rotation.x = 0.3
			if _leg_r:
				_leg_r.rotation.x = 0.1
			if _arm_l:
				_arm_l.rotation.x = -0.9
			if _arm_r:
				_arm_r.rotation.x = -1.0
		AnimState.LAND:
			_reset_parts()
			var k := 1.0 - clampf(_action_t / maxf(_action_duration, 0.01), 0.0, 1.0)
			if _leg_l:
				_leg_l.rotation.x = 0.45 * k
			if _leg_r:
				_leg_r.rotation.x = 0.45 * k
			if _torso:
				_torso.position.y = _base_y(_torso) - 0.12 * k
		AnimState.ATTACK:
			_reset_parts()
			var p := clampf(_action_t / maxf(_action_duration, 0.01), 0.0, 1.0)
			# 举起到下砸（剑：更大横扫）
			if p < 0.35:
				var wind := p / 0.35
				if _arm_r:
					if is_sword:
						_arm_r.rotation = Vector3(lerp(-0.2, -2.4, wind), 0, lerp(0.2, -0.9, wind))
					else:
						_arm_r.rotation.x = lerp(-0.1, -2.2, wind)
				if _torso:
					_torso.rotation.y = lerp(0.0, -0.5 if is_sword else -0.35, wind)
			else:
				var strike := clampf((p - 0.35) / 0.35, 0.0, 1.0)
				if _arm_r:
					if is_sword:
						_arm_r.rotation = Vector3(lerp(-2.4, 0.45, strike), 0, lerp(-0.9, 0.7, strike))
					else:
						_arm_r.rotation.x = lerp(-2.2, 0.6, strike)
				if _torso:
					_torso.rotation.y = lerp(-0.5 if is_sword else -0.35, 0.45 if is_sword else 0.25, strike)
			if _arm_l:
				_arm_l.rotation.x = -0.5
		AnimState.CAST:
			_reset_parts()
			var p2 := clampf(_action_t / maxf(_action_duration, 0.01), 0.0, 1.0)
			if _arm_r:
				_arm_r.rotation.x = lerp(-0.1, -1.8, sin(p2 * PI))
			if _arm_l:
				_arm_l.rotation.x = lerp(-0.1, -1.2, sin(p2 * PI))
			if _torso:
				_torso.rotation.x = -0.15 * sin(p2 * PI)
		AnimState.HIT:
			_reset_parts()
			var p3 := clampf(_action_t / maxf(_action_duration, 0.01), 0.0, 1.0)
			if _torso:
				_torso.rotation.x = -0.25 * (1.0 - p3)
				_torso.position.z = _base_z(_torso) - 0.08 * (1.0 - p3)
		AnimState.DEATH:
			_reset_parts()
			var p4 := clampf(_action_t / 0.6, 0.0, 1.0)
			if _torso:
				_torso.rotation.x = lerp(0.0, 1.35, p4)
				_torso.position.y = _base_y(_torso) - 0.45 * p4
			if _arm_l:
				_arm_l.rotation.x = -1.5 * p4
			if _arm_r:
				_arm_r.rotation.x = -1.5 * p4
			if _leg_l:
				_leg_l.rotation.x = 0.3 * p4
			if _leg_r:
				_leg_r.rotation.x = 0.2 * p4


func _reset_parts() -> void:
	for n in _base.keys():
		if is_instance_valid(n):
			n.rotation = _base[n]
	# torso position reset
	if _torso and _base.has(_torso):
		pass
	if _torso:
		_torso.position.y = _base_y(_torso)
		_torso.position.z = _base_z(_torso)


func _base_y(n: Node3D) -> float:
	return 0.0 if n == null else n.get_meta("base_y", n.position.y)


func _base_z(n: Node3D) -> float:
	return 0.0 if n == null else n.get_meta("base_z", n.position.z)


func capture_base_positions() -> void:
	if _torso:
		_torso.set_meta("base_y", _torso.position.y)
		_torso.set_meta("base_z", _torso.position.z)
