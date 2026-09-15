class_name QuestSystem
extends Node
const GB := preload("res://wow/data/GameBalance.gd")
## 4 chained kill quests.

signal quest_updated(id: int, name: String, desc: String, progress: int, goal: int, reward_exp: int)
signal quest_completed(id: int, reward_exp: int)

const QUESTS := [
	{"id": 1, "name": "猎杀野猪", "desc": "击杀草原野猪", "kill_type": "boar", "goal": 5, "reward_exp": 60},
	{"id": 2, "name": "清除荒漠蝎患", "desc": "击杀荒漠蝎子", "kill_type": "scorpion", "goal": 6, "reward_exp": 100},
	{"id": 3, "name": "驱逐迅猛龙", "desc": "击杀幼年迅猛龙", "kill_type": "raptor", "goal": 7, "reward_exp": 140},
	{"id": 4, "name": "守护沙地边境", "desc": "击杀沙地野兽", "kill_type": "beast", "goal": 8, "reward_exp": 180},
]

var current_index := 0
var progress := 0
var finished := false
var player: Node = null


func start(p: Node) -> void:
	player = p
	current_index = 0
	progress = 0
	finished = false
	_emit_current()


func on_enemy_killed(type_id: String) -> void:
	if finished or current_index >= QUESTS.size():
		return
	var q: Dictionary = QUESTS[current_index]
	if type_id != q["kill_type"]:
		return
	progress += 1
	if progress >= q["goal"]:
		_complete_current()
	else:
		_emit_current()


func _complete_current() -> void:
	var q: Dictionary = QUESTS[current_index]
	if player and player.has_method("stats") and player.stats:
		player.stats.gain_exp(q["reward_exp"])
	quest_completed.emit(q["id"], q["reward_exp"])
	current_index += 1
	progress = 0
	if current_index >= QUESTS.size():
		finished = true
		quest_updated.emit(-1, "全部完成", "新手任务链已完成", 0, 0, 0)
	else:
		_emit_current()


func _emit_current() -> void:
	if finished or current_index >= QUESTS.size():
		return
	var q: Dictionary = QUESTS[current_index]
	quest_updated.emit(q["id"], q["name"], q["desc"], progress, q["goal"], q["reward_exp"])


func get_display() -> String:
	if finished:
		return "任务：全部完成"
	var q: Dictionary = QUESTS[current_index]
	return "任务：%s\n%s  %d/%d\n奖励经验 %d" % [q["name"], q["desc"], progress, q["goal"], q["reward_exp"]]
