class_name DummyEnemy
extends CharacterBody3D
const GB := preload("res://wow/data/GameBalance.gd")
## Training dummy: selectable, damageable, respawn. No full AI.

signal died_signal

@export var display_name := "木桩假人"
@export var max_hp := 50.0
@export var level := 1
@export var exp_reward := 10
@export var creature_type := "目标"

var hp: float
var _dead := false
var _respawn_t := 0.0
var _home: Vector3

@onready var label: Label3D = $Label3D
@onready var visual: Node3D = $Visual


func _ready() -> void:
	add_to_group("enemies")
	hp = max_hp
	_home = global_position
	if label:
		label.text = "%s Lv%d" % [display_name, level]


func _process(delta: float) -> void:
	if _dead:
		_respawn_t -= delta
		if _respawn_t <= 0.0:
			_revive()
		return
	if visual:
		visual.position.y = absf(sin(Time.get_ticks_msec() / 800.0)) * 0.03


func is_alive() -> bool:
	return not _dead


func is_aggro() -> bool:
	return false


func take_damage(amount: float, from: Node = null) -> void:
	if _dead:
		return
	hp = maxf(hp - amount, 0.0)
	_flash()
	if from is Player:
		from.stats.enter_combat()
	if hp <= 0.0:
		_die(from)


func apply_stun(_t: float) -> void:
	pass


func _flash() -> void:
	if visual == null:
		return
	for c in visual.get_children():
		if c is MeshInstance3D:
			var mat := c.material_override as StandardMaterial3D
			if mat:
				var old := mat.albedo_color
				mat.albedo_color = Color(1, 0.4, 0.3)
				get_tree().create_timer(0.08).timeout.connect(func() -> void:
					if is_instance_valid(mat):
						mat.albedo_color = old
				)


func _die(from: Node = null) -> void:
	_dead = true
	_respawn_t = GB.ENEMY_RESPAWN_TIME
	if from is Player:
		from.stats.gain_exp(exp_reward)
		from.clear_target()
	died_signal.emit()
	if visual:
		visual.visible = false
	if label:
		label.visible = false
	collision_layer = 0
	collision_mask = 0


func _revive() -> void:
	_dead = false
	hp = max_hp
	global_position = _home
	if visual:
		visual.visible = true
		visual.rotation = Vector3.ZERO
	if label:
		label.visible = true
	collision_layer = 4
	collision_mask = 1
