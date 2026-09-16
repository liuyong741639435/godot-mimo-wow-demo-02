class_name QuestSystem
extends Node
const GB := preload("res://wow/data/GameBalance.gd")
## 任务链：1-5 自动接取；6-10 需 NPC 接取/交还。

signal quest_updated(id: int, name: String, desc: String, progress: int, goal: int, reward_exp: int)
signal quest_completed(id: int, reward_exp: int)
signal quest_accepted(id: int)
signal npc_quest_state_changed

## mode: auto=自动链, npc=找NPC接取
const QUESTS := [
	{"id": 1, "name": "猎杀野猪", "desc": "击杀草原野猪", "kill_type": "boar", "goal": 5, "reward_exp": 60, "mode": "auto"},
	{"id": 2, "name": "清除荒漠蝎患", "desc": "击杀荒漠蝎子", "kill_type": "scorpion", "goal": 6, "reward_exp": 100, "mode": "auto"},
	{"id": 3, "name": "驱逐迅猛龙", "desc": "击杀幼年迅猛龙", "kill_type": "raptor", "goal": 7, "reward_exp": 140, "mode": "auto"},
	{"id": 4, "name": "守护沙地边境", "desc": "击杀沙地野兽", "kill_type": "beast", "goal": 8, "reward_exp": 180, "mode": "auto"},
	{"id": 5, "name": "前往部落营地", "desc": "与营地NPC对话，领取后续任务", "kill_type": "", "goal": 0, "reward_exp": 80, "mode": "talk"},
	{"id": 6, "name": "半人马威胁", "desc": "击杀科尔卡半人马", "kill_type": "kolkar", "goal": 6, "reward_exp": 220, "mode": "npc"},
	{"id": 7, "name": "鹰身人骚扰", "desc": "击杀荒漠鹰身人", "kill_type": "harpy", "goal": 6, "reward_exp": 280, "mode": "npc"},
	{"id": 8, "name": "雷鳞之患", "desc": "击杀雷霆蜥蜴", "kill_type": "lizard", "goal": 5, "reward_exp": 360, "mode": "npc"},
	{"id": 9, "name": "集结战力", "desc": "击杀任意敌人 x10", "kill_type": "*", "goal": 10, "reward_exp": 420, "mode": "npc"},
	{"id": 10, "name": "讨伐督军", "desc": "击败督军格罗玛什", "kill_type": "boss", "goal": 1, "reward_exp": 800, "mode": "npc"},
]

var current_index := 0
var progress := 0
var finished := false
var player: Node = null
var portal_unlocked := false
var accepted_npc_quest := false
var _kill_all_progress := 0


func start(p: Node) -> void:
	player = p
	current_index = 0
	progress = 0
	finished = false
	portal_unlocked = false
	accepted_npc_quest = false
	_kill_all_progress = 0
	_emit_current()


func get_quest_dict(idx: int) -> Dictionary:
	if idx < 0 or idx >= QUESTS.size():
		return {}
	return QUESTS[idx]


func current_quest() -> Dictionary:
	return get_quest_dict(current_index)


func needs_npc() -> bool:
	if finished:
		return false
	var q := current_quest()
	if q.is_empty():
		return false
	return q["mode"] == "npc" or q["mode"] == "talk"


func can_turn_in() -> bool:
	if finished:
		return false
	var q := current_quest()
	if q.is_empty():
		return false
	if q["mode"] == "talk":
		return true
	if q["mode"] == "npc":
		return accepted_npc_quest and progress >= int(q["goal"])
	return false


func npc_accept() -> bool:
	if finished:
		return false
	var q := current_quest()
	if q.is_empty():
		return false
	if q["mode"] == "talk":
		# 对话完成任务5并解锁传送
		portal_unlocked = true
		_complete_current()
		return true
	if q["mode"] == "npc":
		if accepted_npc_quest:
			return false
		accepted_npc_quest = true
		quest_accepted.emit(q["id"])
		_emit_current()
		npc_quest_state_changed.emit()
		return true
	return false


func npc_turn_in() -> bool:
	if not can_turn_in():
		return false
	_complete_current()
	return true


func on_enemy_killed(type_id: String) -> void:
	if finished or current_index >= QUESTS.size():
		return
	var q: Dictionary = QUESTS[current_index]
	if q["mode"] == "auto":
		if type_id != q["kill_type"]:
			return
		progress += 1
		if progress >= int(q["goal"]):
			_complete_current()
		else:
			_emit_current()
	elif q["mode"] == "npc" and accepted_npc_quest:
		var need: String = str(q["kill_type"])
		if need == "*" or type_id == need:
			progress += 1
			if progress >= int(q["goal"]):
				_emit_current()
			else:
				_emit_current()
	npc_quest_state_changed.emit()


func _complete_current() -> void:
	var q: Dictionary = QUESTS[current_index]
	if player and player.get("stats"):
		player.stats.gain_exp(int(q["reward_exp"]))
	quest_completed.emit(q["id"], int(q["reward_exp"]))
	current_index += 1
	progress = 0
	accepted_npc_quest = false
	if current_index >= QUESTS.size():
		finished = true
		quest_updated.emit(-1, "全部完成", "主线任务链已完成", 0, 0, 0)
	else:
		_emit_current()
	npc_quest_state_changed.emit()


func _emit_current() -> void:
	if finished or current_index >= QUESTS.size():
		return
	var q: Dictionary = QUESTS[current_index]
	quest_updated.emit(q["id"], q["name"], q["desc"], progress, int(q["goal"]), int(q["reward_exp"]))


func get_display() -> String:
	if finished:
		return "任务：全部完成"
	var q: Dictionary = QUESTS[current_index]
	var extra := ""
	if q["mode"] == "npc":
		extra = "\n（与营地NPC对话）" if not accepted_npc_quest else ""
	elif q["mode"] == "talk":
		extra = "\n（前往部落营地）"
	return "任务：%s\n%s  %d/%d\n奖励经验 %d%s" % [q["name"], q["desc"], progress, int(q["goal"]), int(q["reward_exp"]), extra]


func to_dict() -> Dictionary:
	return {
		"current_index": current_index,
		"progress": progress,
		"finished": finished,
		"accepted_npc_quest": accepted_npc_quest,
		"portal_unlocked": portal_unlocked,
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	current_index = clampi(int(data.get("current_index", 0)), 0, QUESTS.size())
	progress = int(data.get("progress", 0))
	finished = bool(data.get("finished", false))
	accepted_npc_quest = bool(data.get("accepted_npc_quest", false))
	portal_unlocked = bool(data.get("portal_unlocked", false))
	_emit_current()
	npc_quest_state_changed.emit()
