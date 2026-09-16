class_name PlayerStats
extends Node
const GB := preload("res://wow/data/GameBalance.gd")
## Player stats: level, exp, hp, rage, potions

signal health_changed(current: float, max_value: float)
signal rage_changed(current: float, max_value: float)
signal exp_changed(current: int, needed: int, level: int)
signal level_up(new_level: int)
signal died
signal potion_count_changed(count: int)
signal potion_cooldown_changed(remain: float, total: float)
signal combat_state_changed(in_combat: bool)

var level: int = 1
var exp: int = 0
var max_hp: float
var hp: float
var rage: float = 0.0
var in_combat: bool = false

var potion_count: int
var potion_cooldown_remain: float = 0.0

var _combat_exit_timer: float = 0.0
var _regen_delay_timer: float = 0.0
var _rage_decay_timer: float = 0.0
var _dead: bool = false


func _ready() -> void:
	max_hp = GB.max_hp_for_level(1)
	hp = max_hp
	potion_count = GB.POTION_COUNT_INIT
	_emit_all()


func _process(delta: float) -> void:
	if _dead:
		return
	_tick_regen(delta)
	_tick_rage(delta)
	_tick_potion_cd(delta)


func get_base_attack() -> float:
	return GB.base_atk_for_level(level)


func get_exp_needed() -> int:
	if level >= GB.PLAYER_LEVEL_MAX:
		return GB.exp_needed_for_level(GB.PLAYER_LEVEL_MAX)
	return GB.exp_needed_for_level(level + 1)


func is_dead() -> bool:
	return _dead


func enter_combat() -> void:
	_combat_exit_timer = 0.0
	_regen_delay_timer = 0.0
	_rage_decay_timer = 0.0
	if not in_combat:
		in_combat = true
		combat_state_changed.emit(true)


func force_exit_combat() -> void:
	if in_combat:
		in_combat = false
		combat_state_changed.emit(false)
	_regen_delay_timer = GB.REGEN_DELAY_AFTER_COMBAT
	_rage_decay_timer = GB.RAGE_DECAY_DELAY


func note_combat_idle(delta: float) -> void:
	if not in_combat:
		return
	_combat_exit_timer += delta
	if _combat_exit_timer >= GB.COMBAT_EXIT_DELAY:
		force_exit_combat()


func take_damage(amount: float) -> void:
	if _dead:
		return
	enter_combat()
	hp = maxf(hp - amount, 0.0)
	add_rage(GB.PLAYER_HIT_RAGE_GAIN)
	health_changed.emit(hp, max_hp)
	if hp <= 0.0:
		_dead = true
		died.emit()


func heal(amount: float) -> void:
	if _dead:
		return
	hp = minf(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


func add_rage(amount: float) -> void:
	rage = clampf(rage + amount, 0.0, GB.RAGE_MAX)
	rage_changed.emit(rage, GB.RAGE_MAX)


func spend_rage(amount: float) -> bool:
	if rage < amount:
		return false
	rage -= amount
	rage_changed.emit(rage, GB.RAGE_MAX)
	return true


func gain_exp(amount: int) -> void:
	if _dead or amount <= 0:
		return
	if level >= GB.PLAYER_LEVEL_MAX and exp >= GB.exp_needed_for_level(GB.PLAYER_LEVEL_MAX):
		exp_changed.emit(exp, get_exp_needed(), level)
		return
	exp += amount
	_check_level_up()
	exp_changed.emit(exp, get_exp_needed(), level)


func try_use_potion() -> bool:
	if _dead:
		return false
	if potion_count <= 0 or potion_cooldown_remain > 0.0:
		return false
	if hp >= max_hp:
		return false
	potion_count -= 1
	potion_cooldown_remain = GB.POTION_COOLDOWN
	heal(GB.POTION_HEAL_AMOUNT)
	potion_count_changed.emit(potion_count)
	potion_cooldown_changed.emit(potion_cooldown_remain, GB.POTION_COOLDOWN)
	return true


func respawn_at(_origin: Vector3) -> void:
	_dead = false
	max_hp = GB.max_hp_for_level(level)
	hp = max_hp
	rage = 0.0
	force_exit_combat()
	health_changed.emit(hp, max_hp)
	rage_changed.emit(rage, GB.RAGE_MAX)
	combat_state_changed.emit(false)


func _check_level_up() -> void:
	while level < GB.PLAYER_LEVEL_MAX:
		var need: int = GB.exp_needed_for_level(level + 1)
		if exp < need:
			break
		var old_max := max_hp
		level += 1
		max_hp = GB.max_hp_for_level(level)
		if hp >= old_max:
			hp = max_hp
		else:
			hp = minf(max_hp, hp / old_max * max_hp)
		level_up.emit(level)
		health_changed.emit(hp, max_hp)


func _tick_regen(delta: float) -> void:
	if in_combat or hp >= max_hp:
		_regen_delay_timer = 0.0
		return
	_regen_delay_timer += delta
	if _regen_delay_timer < GB.REGEN_DELAY_AFTER_COMBAT:
		return
	heal(max_hp * GB.REGEN_PERCENT_PER_SEC * delta)


func _tick_rage(delta: float) -> void:
	if in_combat or rage <= 0.0:
		_rage_decay_timer = 0.0
		return
	_rage_decay_timer += delta
	if _rage_decay_timer < GB.RAGE_DECAY_DELAY:
		return
	rage = maxf(rage - GB.RAGE_DECAY_PER_SEC * delta, 0.0)
	rage_changed.emit(rage, GB.RAGE_MAX)


func _tick_potion_cd(delta: float) -> void:
	if potion_cooldown_remain <= 0.0:
		return
	potion_cooldown_remain = maxf(potion_cooldown_remain - delta, 0.0)
	potion_cooldown_changed.emit(potion_cooldown_remain, GB.POTION_COOLDOWN)


func _emit_all() -> void:
	health_changed.emit(hp, max_hp)
	rage_changed.emit(rage, GB.RAGE_MAX)
	exp_changed.emit(exp, get_exp_needed(), level)
	potion_count_changed.emit(potion_count)
	combat_state_changed.emit(in_combat)
