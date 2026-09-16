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
	for id in ["heroic", "charge", "intercept", "whirlwind", "potion", "rend", "thunder", "execute", "mortal", "bladestorm"]:
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


func _melee_target_ok(mult_range_bonus: float = 0.3) -> bool:
	if player == null:
		return false
	var target = player.get("current_target")
	if target == null or not is_instance_valid(target):
		return false
	return player.global_position.distance_to(target.global_position) <= GB.PLAYER_MELEE_RANGE + mult_range_bonus


func try_rend() -> bool:
	if stats == null or stats.level < GB.REND_UNLOCK_LEVEL:
		skill_failed.emit(&"rend", "level too low")
		return false
	if _cd["rend"] > 0.0:
		return false
	if stats.rage < GB.REND_RAGE_COST or not _melee_target_ok():
		skill_failed.emit(&"rend", "need target/rage")
		return false
	if not stats.spend_rage(GB.REND_RAGE_COST):
		return false
	_cd["rend"] = GB.REND_COOLDOWN
	cooldown_updated.emit(&"rend", _cd["rend"], GB.REND_COOLDOWN)
	skill_used.emit(&"rend")
	return true


func try_thunder() -> bool:
	if stats == null or stats.level < GB.THUNDER_UNLOCK_LEVEL:
		skill_failed.emit(&"thunder", "level too low")
		return false
	if _cd["thunder"] > 0.0:
		return false
	if stats.rage < GB.THUNDER_RAGE_COST:
		skill_failed.emit(&"thunder", "not enough rage")
		return false
	if not stats.spend_rage(GB.THUNDER_RAGE_COST):
		return false
	_cd["thunder"] = GB.THUNDER_COOLDOWN
	cooldown_updated.emit(&"thunder", _cd["thunder"], GB.THUNDER_COOLDOWN)
	skill_used.emit(&"thunder")
	return true


func try_execute() -> bool:
	if stats == null or player == null or stats.level < GB.EXECUTE_UNLOCK_LEVEL:
		skill_failed.emit(&"execute", "level too low")
		return false
	if _cd["execute"] > 0.0:
		return false
	if stats.rage < GB.EXECUTE_RAGE_COST or not _melee_target_ok():
		skill_failed.emit(&"execute", "need target/rage")
		return false
	var target = player.get("current_target")
	if target.has_method("is_alive") and not target.is_alive():
		return false
	if "hp" in target and "max_hp" in target and target.max_hp > 0:
		if target.hp / target.max_hp > GB.EXECUTE_HP_THRESHOLD:
			skill_failed.emit(&"execute", "target not low enough")
			return false
	if not stats.spend_rage(GB.EXECUTE_RAGE_COST):
		return false
	_cd["execute"] = GB.EXECUTE_COOLDOWN
	cooldown_updated.emit(&"execute", _cd["execute"], GB.EXECUTE_COOLDOWN)
	skill_used.emit(&"execute")
	return true


func try_mortal() -> bool:
	if stats == null or stats.level < GB.MORTAL_UNLOCK_LEVEL:
		skill_failed.emit(&"mortal", "level too low")
		return false
	if _cd["mortal"] > 0.0:
		return false
	if stats.rage < GB.MORTAL_RAGE_COST or not _melee_target_ok():
		skill_failed.emit(&"mortal", "need target/rage")
		return false
	if not stats.spend_rage(GB.MORTAL_RAGE_COST):
		return false
	_cd["mortal"] = GB.MORTAL_COOLDOWN
	cooldown_updated.emit(&"mortal", _cd["mortal"], GB.MORTAL_COOLDOWN)
	skill_used.emit(&"mortal")
	return true


func try_bladestorm() -> bool:
	if stats == null or stats.level < GB.BLADESTORM_UNLOCK_LEVEL:
		skill_failed.emit(&"bladestorm", "level too low")
		return false
	if _cd["bladestorm"] > 0.0:
		return false
	if stats.rage < GB.BLADESTORM_RAGE_COST:
		skill_failed.emit(&"bladestorm", "not enough rage")
		return false
	if not stats.spend_rage(GB.BLADESTORM_RAGE_COST):
		return false
	_cd["bladestorm"] = GB.BLADESTORM_COOLDOWN
	cooldown_updated.emit(&"bladestorm", _cd["bladestorm"], GB.BLADESTORM_COOLDOWN)
	skill_used.emit(&"bladestorm")
	return true


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
		"rend":
			return GB.REND_COOLDOWN
		"thunder":
			return GB.THUNDER_COOLDOWN
		"execute":
			return GB.EXECUTE_COOLDOWN
		"mortal":
			return GB.MORTAL_COOLDOWN
		"bladestorm":
			return GB.BLADESTORM_COOLDOWN
	return 1.0
