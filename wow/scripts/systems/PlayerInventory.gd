class_name PlayerInventory
extends Node
## 背包：武器实例、材料、分解、强化、装备。

signal inventory_changed
signal equipment_changed(weapon_id: String, display_name: String)
signal material_changed

const WD := preload("res://wow/data/WeaponData.gd")

var equipped_weapon_uid := -1
var items: Array = []
var materials: Dictionary = {}
var _uid := 0


func _ready() -> void:
	materials = {
		"iron_shard": 0,
		"magic_shard": 0,
		"storm_core": 0,
		"warlord_core": 0,
	}
	items.append({
		"uid": 0,
		"id": "none",
		"kind": "weapon",
		"quality": "common",
		"enhance": 0,
		"name": "战斧",
		"qty": 1,
		"atk_bonus": 0.0,
		"color": Color(0.58, 0.58, 0.62),
		"vfx": Color(1, 0.95, 0.7),
		"scale": 1.0,
		"desc": "初始武器",
		"equipped": true,
	})
	equipped_weapon_uid = 0
	items.append({
		"uid": -1,
		"id": "potion",
		"kind": "consumable",
		"quality": "common",
		"enhance": 0,
		"name": "初级治疗药水",
		"qty": 3,
		"atk_bonus": 0.0,
		"color": Color(0.3, 0.9, 0.4),
		"desc": "恢复生命",
	})
	inventory_changed.emit()


func add_weapon_drop(weapon_instance: Dictionary) -> void:
	if weapon_instance.is_empty():
		return
	_uid += 1
	var it: Dictionary = weapon_instance.duplicate(true)
	it["uid"] = _uid
	it["kind"] = "weapon"
	it["qty"] = 1
	items.append(it)
	inventory_changed.emit()


func add_material(mat_id: String, amount: int) -> void:
	if amount <= 0:
		return
	materials[mat_id] = int(materials.get(mat_id, 0)) + amount
	material_changed.emit()
	inventory_changed.emit()


func equip_uid(uid: int) -> bool:
	var idx := _find_index(uid)
	if idx < 0:
		return false
	var it: Dictionary = items[idx]
	if it["kind"] != "weapon":
		return false
	for x in items:
		if x.get("kind") == "weapon":
			x["equipped"] = (int(x.get("uid", -1)) == uid)
	it["equipped"] = true
	equipped_weapon_uid = uid
	equipment_changed.emit(str(it["id"]), str(it["name"]))
	inventory_changed.emit()
	return true


func equip_index(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var it: Dictionary = items[index]
	if it["kind"] != "weapon":
		return false
	return equip_uid(int(it.get("uid", -1)))


func get_equipped_weapon() -> String:
	var idx := _find_index(equipped_weapon_uid)
	if idx < 0:
		return "none"
	return str(items[idx].get("id", "none"))


func get_equipped_item() -> Dictionary:
	var idx := _find_index(equipped_weapon_uid)
	if idx < 0:
		return {}
	return items[idx]


func get_weapon_bonus() -> float:
	var it := get_equipped_item()
	if it.is_empty():
		return 0.0
	return float(it.get("atk_bonus", 0.0))


func get_weapon_instance_for_visual() -> Dictionary:
	return get_equipped_item()


func update_potion_qty(qty: int) -> void:
	for it in items:
		if str(it.get("id")) == "potion":
			it["qty"] = qty
			inventory_changed.emit()
			return


func decompose_index(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var it: Dictionary = items[index]
	if it.get("kind") != "weapon":
		return false
	if int(it.get("uid", -1)) == equipped_weapon_uid:
		return false
	var q: String = str(it.get("quality", "common"))
	var yield: Dictionary = WD.decompose_yield(q)
	for k in yield:
		add_material(str(k), int(yield[k]))
	items.remove_at(index)
	inventory_changed.emit()
	return true


func enhance_equipped() -> bool:
	var idx := _find_index(equipped_weapon_uid)
	if idx < 0:
		return false
	var it: Dictionary = items[idx]
	if it.get("kind") != "weapon":
		return false
	if it.get("id") == "none":
		return false
	var lvl: int = int(it.get("enhance", 0))
	if lvl >= WD.ENHANCE_MAX_LEVEL:
		return false
	var cost: Dictionary = WD.enhance_cost(lvl)
	for k in cost:
		if int(materials.get(k, 0)) < int(cost[k]):
			return false
	for k in cost:
		materials[k] = int(materials[k]) - int(cost[k])
	it["enhance"] = lvl + 1
	var base_id: String = str(it["id"])
	var q: String = str(it["quality"])
	it["atk_bonus"] = WD.calc_atk(base_id, q, int(it["enhance"]))
	it["name"] = str(WD.make_weapon_instance(base_id, q, int(it["enhance"]))["name"])
	material_changed.emit()
	inventory_changed.emit()
	equipment_changed.emit(str(it["id"]), str(it["name"]))
	return true


func can_enhance_equipped() -> bool:
	var idx := _find_index(equipped_weapon_uid)
	if idx < 0:
		return false
	var it: Dictionary = items[idx]
	if it.get("kind") != "weapon" or it.get("id") == "none":
		return false
	if int(it.get("enhance", 0)) >= WD.ENHANCE_MAX_LEVEL:
		return false
	var cost: Dictionary = WD.enhance_cost(int(it.get("enhance", 0)))
	for k in cost:
		if int(materials.get(k, 0)) < int(cost[k]):
			return false
	return true


func _find_index(uid: int) -> int:
	for i in range(items.size()):
		if int(items[i].get("uid", -999)) == uid:
			return i
	return -1


func describe_index(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	var it: Dictionary = items[index]
	if it.get("kind") == "weapon":
		var qn: String = WD.quality_name(str(it.get("quality", "common")))
		var en: int = int(it.get("enhance", 0))
		var extra := ""
		if en > 0:
			extra = " +%d" % en
		return "[%s]%s %s\n攻击 +%s\n%s" % [qn, extra, it["name"], str(it["atk_bonus"]), it.get("desc", "")]
	return "%s x%s" % [it["name"], it["qty"]]


func materials_text() -> String:
	var parts: Array = []
	for k in materials:
		var info: Dictionary = WD.SALVAGE[k]
		parts.append("%s×%d" % [info["name"], int(materials[k])])
	return "  ".join(parts)
