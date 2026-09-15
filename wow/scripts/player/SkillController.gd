class_name SkillController
extends Node
const GB := preload("res://wow/data/GameBalance.gd")
## Skill cooldowns: 1 heroic, 2 charge, 3 intercept, 4 whirlwind, 5 potion

signal skill_used(id: StringName)
signal skill_failed(id: StringName, reason: String)
signal cooldown_updated(id: StringName, remain: float, total: float)

var _cd: Dictionary = {}
var player: Node3D
var stats: PlayerStats


func _ready() -> void:
	for id in ["heroic", "charge", "intercept", "whirlwind", "potion"]:
		_cd[id] = 0.0


func setup(p: Node3D, s: PlayerStats) -> void:
	player = p
	stats = s


func _process(delta: float) -> void:
	for id in _cd.keys():
		if float(_cd[id]) > 0.0:
			_cd[id] = maxf(float(_cd[id]) - delta, 0.0)
			cooldown_updated.emit(StringName(id), float(_cd[id]), _total_cd(id))


func try_heroic() -> bool:
	if _cd["heroic"] > 0.0:
		return false
	if stats == null:
		return false
	if stats.rage < GB.HEROIC_RAGE_COST:
		skill_failed.emit(&"heroic", "not enough rage")
		return false
	var target = player.get("current_target") if player else null
	if target == null or not is_instance_valid(target):
		skill_failed.emit(&"heroic", "need target")
		return false
	if player.global_position.distance_to(target.global_position) > GB.PLAYER_MELEE_RANGE + 0.3:
		skill_failed.emit(&"heroic", "out of range")
		return false
	if not stats.spend_rage(GB.HEROIC_RAGE_COST):
		return false
	_cd["heroic"] = GB.HEROIC_COOLDOWN
	cooldown_updated.emit(&"heroic", _cd["heroic"], GB.HEROIC_COOLDOWN)
	skill_used.emit(&"heroic")
	return true


func try_charge() -> bool:
	if _cd["charge"] > 0.0:
		return false
	if stats and stats.in_combat:
		skill_failed.emit(&"charge", "out of combat only")
		return false
	_cd["charge"] = GB.CHARGE_COOLDOWN
	cooldown_updated.emit(&"charge", _cd["charge"], GB.CHARGE_COOLDOWN)
	skill_used.emit(&"charge")
	return true


func try_intercept() -> bool:
	if stats == null or player == null:
		return false
	if stats.level < GB.INTERCEPT_UNLOCK_LEVEL:
		skill_failed.emit(&"intercept", "level too low")
		return false
	if _cd["intercept"] > 0.0:
		return false
	if not stats.in_combat:
		skill_failed.emit(&"intercept", "combat only")
		return false
	if stats.rage < GB.INTERCEPT_RAGE_COST:
		skill_failed.emit(&"intercept", "not enough rage")
		return false
	var target = player.get("current_target")
	if target == null or not is_instance_valid(target):
		skill_failed.emit(&"intercept", "need target")
		return false
	if player.global_position.distance_to(target.global_position) > GB.INTERCEPT_MAX_DISTANCE:
		skill_failed.emit(&"intercept", "out of range")
		return false
	if not stats.spend_rage(GB.INTERCEPT_RAGE_COST):
		return false
	_cd["intercept"] = GB.INTERCEPT_COOLDOWN
	cooldown_updated.emit(&"intercept", _cd["intercept"], GB.INTERCEPT_COOLDOWN)
	skill_used.emit(&"intercept")
	return true


func try_whirlwind() -> bool:
	if stats == null:
		return false
	if stats.level < GB.WHIRLWIND_UNLOCK_LEVEL:
		skill_failed.emit(&"whirlwind", "level too low")
		return false
	if _cd["whirlwind"] > 0.0:
		return false
	if stats.rage < GB.WHIRLWIND_RAGE_COST:
		skill_failed.emit(&"whirlwind", "not enough rage")
		return false
	if not stats.spend_rage(GB.WHIRLWIND_RAGE_COST):
		return false
	_cd["whirlwind"] = GB.WHIRLWIND_COOLDOWN
	cooldown_updated.emit(&"whirlwind", _cd["whirlwind"], GB.WHIRLWIND_COOLDOWN)
	skill_used.emit(&"whirlwind")
	return true


func try_potion() -> bool:
	if _cd["potion"] > 0.0:
		return false
	if stats and stats.try_use_potion():
		_cd["potion"] = GB.POTION_COOLDOWN
		cooldown_updated.emit(&"potion", _cd["potion"], GB.POTION_COOLDOWN)
		skill_used.emit(&"potion")
		return true
	skill_failed.emit(&"potion", "cannot use potion")
	return false


func _total_cd(id: String) -> float:
	match id:
		"heroic":
			return GB.HEROIC_COOLDOWN
		"charge":
			return GB.CHARGE_COOLDOWN
		"intercept":
			return GB.INTERCEPT_COOLDOWN
		"whirlwind":
			return GB.WHIRLWIND_COOLDOWN
		"potion":
			return GB.POTION_COOLDOWN
	return 1.0
