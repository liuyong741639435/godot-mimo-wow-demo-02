class_name SaveSystem
extends RefCounted
## JSON 存档：user://wow_save.json

const SAVE_PATH := "user://wow_save.json"
const VERSION := 1


static func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


static func save_game(player: Node, inventory: Node, quests: Node) -> bool:
	if player == null or inventory == null:
		return false
	var stats = player.get("stats")
	var data := {
		"version": VERSION,
		"time": Time.get_unix_time_from_system(),
		"player": {
			"level": int(stats.level) if stats else 1,
			"exp": int(stats.exp) if stats else 0,
			"hp": float(stats.hp) if stats else 100.0,
			"rage": float(stats.rage) if stats else 0.0,
			"potion_count": int(stats.potion_count) if stats else 0,
		},
		"inventory": inventory.to_dict() if inventory.has_method("to_dict") else {},
		"quests": {},
		"world": "valley",
	}
	if quests and quests.has_method("to_dict"):
		data["quests"] = quests.to_dict()
	elif quests:
		data["quests"] = {
			"current_index": int(quests.get("current_index")) if "current_index" in quests else 0,
			"progress": int(quests.get("progress")) if "progress" in quests else 0,
			"finished": bool(quests.get("finished")) if "finished" in quests else false,
			"accepted_npc_quest": bool(quests.get("accepted_npc_quest")) if "accepted_npc_quest" in quests else false,
			"portal_unlocked": bool(quests.get("portal_unlocked")) if "portal_unlocked" in quests else false,
		}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(data, "  "))
	f.close()
	return true


static func load_game() -> Dictionary:
	if not has_save():
		return {}
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return {}
	var text := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


static func apply_save(data: Dictionary, player: Node, inventory: Node, quests: Node) -> bool:
	if data.is_empty() or player == null:
		return false
	var p = data.get("player", {})
	if p is Dictionary and inventory and inventory.has_method("from_dict"):
		# 先恢复背包（含药水数量），再恢复角色
		var inv_data = data.get("inventory", {})
		if inv_data is Dictionary:
			inventory.from_dict(inv_data)
	var stats = player.get("stats")
	if stats and p is Dictionary:
		stats.level = int(p.get("level", 1))
		stats.exp = int(p.get("exp", 0))
		stats.max_hp = float(preload("res://wow/data/GameBalance.gd").max_hp_for_level(stats.level))
		if inventory and inventory.has_method("get_armor_hp_bonus"):
			stats.max_hp += inventory.get_armor_hp_bonus()
		stats.hp = clampf(float(p.get("hp", stats.max_hp)), 1.0, stats.max_hp)
		stats.rage = clampf(float(p.get("rage", 0.0)), 0.0, 100.0)
		if inventory and inventory.has_method("get_potion_qty"):
			stats.potion_count = inventory.get_potion_qty()
		else:
			stats.potion_count = int(p.get("potion_count", 3))
		if stats.has_method("_emit_all"):
			stats._emit_all()
	# 武器外观
	if inventory and player.has_method("equip_from_item"):
		var it: Dictionary = inventory.get_equipped_item()
		if not it.is_empty():
			player.equip_from_item(it)
	# 任务
	if quests:
		var q = data.get("quests", {})
		if q is Dictionary:
			if quests.has_method("from_dict"):
				quests.from_dict(q)
			else:
				for k in ["current_index", "progress", "finished", "accepted_npc_quest", "portal_unlocked"]:
					if q.has(k):
						quests.set(k, q[k])
	return true


static func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
