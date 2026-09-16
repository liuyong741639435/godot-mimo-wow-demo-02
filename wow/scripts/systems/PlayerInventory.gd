class_name PlayerInventory
extends Node
## 背包：武器/护甲实例、材料、分解、强化、装备槽、出售、序列化。

signal inventory_changed
signal equipment_changed(slot: String, display_name: String)
signal material_changed
signal bag_full_rejected(item_name: String)

const WD := preload("res://wow/data/WeaponData.gd")
const AD := preload("res://wow/data/ArmorData.gd")

const BAG_CAPACITY := 24
const KIND_WEAPON := "weapon"
const KIND_ARMOR := "armor"
const KIND_CONSUMABLE := "consumable"

var equipped_weapon_uid := -1
## slot -> uid
var equipped_armor := {
	AD.SLOT_HEAD: -1,
	AD.SLOT_CHEST: -1,
	AD.SLOT_TRINKET: -1,
}
var items: Array = []
var materials: Dictionary = {}
var _uid := 0


func _ready() -> void:
	reset_to_new_game()


func reset_to_new_game() -> void:
	items.clear()
	equipped_armor = {AD.SLOT_HEAD: -1, AD.SLOT_CHEST: -1, AD.SLOT_TRINKET: -1}
	_uid = 0
	materials = {
		"iron_shard": 0,
		"magic_shard": 0,
		"storm_core": 0,
		"warlord_core": 0,
	}
	items.append({
		"uid": 0,
		"id": "none",
		"kind": KIND_WEAPON,
		"slot": "weapon",
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
		"kind": KIND_CONSUMABLE,
		"slot": "",
		"quality": "common",
		"enhance": 0,
		"name": "初级治疗药水",
		"qty": 3,
		"atk_bonus": 0.0,
		"color": Color(0.3, 0.9, 0.4),
		"desc": "恢复生命",
	})
	inventory_changed.emit()


func equipment_slot_count() -> int:
	var n := 0
	for it in items:
		var k := str(it.get("kind", ""))
		if k == KIND_WEAPON or k == KIND_ARMOR:
			n += 1
	return n


func is_bag_full() -> bool:
	return equipment_slot_count() >= BAG_CAPACITY


func add_weapon_drop(weapon_instance: Dictionary) -> bool:
	if weapon_instance.is_empty():
		return false
	if is_bag_full():
		bag_full_rejected.emit(str(weapon_instance.get("name", "武器")))
		return false
	_uid += 1
	var it: Dictionary = weapon_instance.duplicate(true)
	it["uid"] = _uid
	it["kind"] = KIND_WEAPON
	it["slot"] = "weapon"
	it["qty"] = 1
	items.append(it)
	inventory_changed.emit()
	return true


func add_armor_drop(armor_instance: Dictionary) -> bool:
	if armor_instance.is_empty():
		return false
	if is_bag_full():
		bag_full_rejected.emit(str(armor_instance.get("name", "护甲")))
		return false
	_uid += 1
	var it: Dictionary = armor_instance.duplicate(true)
	it["uid"] = _uid
	it["kind"] = KIND_ARMOR
	it["qty"] = 1
	items.append(it)
	inventory_changed.emit()
	return true


func add_material(mat_id: String, amount: int) -> void:
	if amount <= 0:
		return
	materials[mat_id] = int(materials.get(mat_id, 0)) + amount
	material_changed.emit()
	inventory_changed.emit()


func spend_material(mat_id: String, amount: int) -> bool:
	if amount <= 0:
		return true
	if int(materials.get(mat_id, 0)) < amount:
		return false
	materials[mat_id] = int(materials[mat_id]) - amount
	material_changed.emit()
	inventory_changed.emit()
	return true


func equip_uid(uid: int) -> bool:
	var idx := _find_index(uid)
	if idx < 0:
		return false
	var it: Dictionary = items[idx]
	var kind := str(it.get("kind", ""))
	if kind == KIND_WEAPON:
		for x in items:
			if x.get("kind") == KIND_WEAPON:
				x["equipped"] = (int(x.get("uid", -1)) == uid)
		it["equipped"] = true
		equipped_weapon_uid = uid
		equipment_changed.emit("weapon", str(it["name"]))
		inventory_changed.emit()
		return true
	if kind == KIND_ARMOR:
		var slot := str(it.get("slot", ""))
		if not equipped_armor.has(slot):
			return false
		for x in items:
			if x.get("kind") == KIND_ARMOR and str(x.get("slot", "")) == slot:
				x["equipped"] = (int(x.get("uid", -1)) == uid)
		it["equipped"] = true
		equipped_armor[slot] = uid
		equipment_changed.emit(slot, str(it["name"]))
		inventory_changed.emit()
		return true
	return false


func equip_index(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var it: Dictionary = items[index]
	var kind := str(it.get("kind", ""))
	if kind != KIND_WEAPON and kind != KIND_ARMOR:
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


func get_equipped_armor_item(slot: String) -> Dictionary:
	var uid: int = int(equipped_armor.get(slot, -1))
	var idx := _find_index(uid)
	if idx < 0:
		return {}
	return items[idx]


func get_weapon_bonus() -> float:
	var it := get_equipped_item()
	if it.is_empty():
		return 0.0
	return float(it.get("atk_bonus", 0.0))


func get_armor_def_bonus() -> float:
	var total := 0.0
	for slot in equipped_armor:
		var it := get_equipped_armor_item(str(slot))
		if not it.is_empty():
			total += float(it.get("def_bonus", 0.0))
	return total


func get_armor_hp_bonus() -> float:
	var total := 0.0
	for slot in equipped_armor:
		var it := get_equipped_armor_item(str(slot))
		if not it.is_empty():
			total += float(it.get("hp_bonus", 0.0))
	return total


func get_weapon_instance_for_visual() -> Dictionary:
	return get_equipped_item()


func update_potion_qty(qty: int) -> void:
	for it in items:
		if str(it.get("id")) == "potion":
			it["qty"] = qty
			inventory_changed.emit()
			return


func add_potion(count: int) -> void:
	if count <= 0:
		return
	for it in items:
		if str(it.get("id")) == "potion":
			it["qty"] = int(it.get("qty", 0)) + count
			inventory_changed.emit()
			return
	# 没有药水条目则新建
	items.append({
		"uid": -1,
		"id": "potion",
		"kind": KIND_CONSUMABLE,
		"slot": "",
		"quality": "common",
		"enhance": 0,
		"name": "初级治疗药水",
		"qty": count,
		"atk_bonus": 0.0,
		"color": Color(0.3, 0.9, 0.4),
		"desc": "恢复生命",
	})
	inventory_changed.emit()


func get_potion_qty() -> int:
	for it in items:
		if str(it.get("id")) == "potion":
			return int(it.get("qty", 0))
	return 0


func decompose_index(index: int) -> bool:
	if index < 0 or index >= items.size():
		return false
	var it: Dictionary = items[index]
	var kind := str(it.get("kind", ""))
	if kind != KIND_WEAPON and kind != KIND_ARMOR:
		return false
	if _is_equipped_item(it):
		return false
	var q: String = str(it.get("quality", "common"))
	var salvage: Dictionary = WD.decompose_yield(q)
	for k in salvage:
		add_material(str(k), int(salvage[k]))
	items.remove_at(index)
	inventory_changed.emit()
	return true


func sell_index(index: int) -> bool:
	## 商人出售：返还材料，移除物品
	if index < 0 or index >= items.size():
		return false
	var it: Dictionary = items[index]
	var kind := str(it.get("kind", ""))
	if kind != KIND_WEAPON and kind != KIND_ARMOR:
		return false
	if _is_equipped_item(it):
		return false
	if str(it.get("id", "")) == "none":
		return false
	var q: String = str(it.get("quality", "common"))
	var en: int = int(it.get("enhance", 0))
	var value: Dictionary = AD.sell_value(q, en)
	for k in value:
		add_material(str(k), int(value[k]))
	items.remove_at(index)
	inventory_changed.emit()
	return true


func buy_potion(count: int, cost_per: Dictionary) -> bool:
	if count <= 0:
		return false
	for k in cost_per:
		if int(materials.get(k, 0)) < int(cost_per[k]) * count:
			return false
	for k in cost_per:
		materials[k] = int(materials[k]) - int(cost_per[k]) * count
	add_potion(count)
	material_changed.emit()
	inventory_changed.emit()
	return true


func enhance_equipped() -> bool:
	return enhance_item_uid(equipped_weapon_uid)


func enhance_item_uid(uid: int) -> bool:
	var idx := _find_index(uid)
	if idx < 0:
		return false
	var it: Dictionary = items[idx]
	var kind := str(it.get("kind", ""))
	if kind != KIND_WEAPON and kind != KIND_ARMOR:
		return false
	if kind == KIND_WEAPON and it.get("id") == "none":
		return false
	var lvl: int = int(it.get("enhance", 0))
	if lvl >= WD.ENHANCE_MAX_LEVEL:
		return false
	var cost: Dictionary = WD.enhance_cost(lvl) if kind == KIND_WEAPON else AD.enhance_cost(lvl)
	for k in cost:
		if int(materials.get(k, 0)) < int(cost[k]):
			return false
	for k in cost:
		materials[k] = int(materials[k]) - int(cost[k])
	it["enhance"] = lvl + 1
	var base_id: String = str(it["id"])
	var q: String = str(it["quality"])
	if kind == KIND_WEAPON:
		it["atk_bonus"] = WD.calc_atk(base_id, q, int(it["enhance"]))
		it["name"] = str(WD.make_weapon_instance(base_id, q, int(it["enhance"]))["name"])
	else:
		it["def_bonus"] = AD.calc_def(base_id, q, int(it["enhance"]))
		it["hp_bonus"] = AD.calc_hp(base_id, q, int(it["enhance"]))
		it["name"] = str(AD.make_armor_instance(base_id, q, int(it["enhance"]))["name"])
	material_changed.emit()
	inventory_changed.emit()
	equipment_changed.emit(str(it.get("slot", kind)), str(it["name"]))
	return true


func can_enhance_equipped() -> bool:
	return can_enhance_uid(equipped_weapon_uid)


func can_enhance_uid(uid: int) -> bool:
	var idx := _find_index(uid)
	if idx < 0:
		return false
	var it: Dictionary = items[idx]
	var kind := str(it.get("kind", ""))
	if kind != KIND_WEAPON and kind != KIND_ARMOR:
		return false
	if kind == KIND_WEAPON and it.get("id") == "none":
		return false
	if int(it.get("enhance", 0)) >= WD.ENHANCE_MAX_LEVEL:
		return false
	var cost: Dictionary = WD.enhance_cost(int(it.get("enhance", 0))) if kind == KIND_WEAPON else AD.enhance_cost(int(it.get("enhance", 0)))
	for k in cost:
		if int(materials.get(k, 0)) < int(cost[k]):
			return false
	return true


func _is_equipped_item(it: Dictionary) -> bool:
	var uid := int(it.get("uid", -999))
	if it.get("kind") == KIND_WEAPON:
		return uid == equipped_weapon_uid
	if it.get("kind") == KIND_ARMOR:
		var slot := str(it.get("slot", ""))
		return int(equipped_armor.get(slot, -1)) == uid
	return false


func _find_index(uid: int) -> int:
	for i in range(items.size()):
		if int(items[i].get("uid", -999)) == uid:
			return i
	return -1


func describe_index(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	var it: Dictionary = items[index]
	var kind := str(it.get("kind", ""))
	var qn: String = WD.quality_name(str(it.get("quality", "common")))
	var en: int = int(it.get("enhance", 0))
	var extra := ""
	if en > 0:
		extra = " +%d" % en
	if kind == KIND_WEAPON:
		return "[%s]%s %s\n攻击 +%s\n%s" % [qn, extra, it["name"], str(it["atk_bonus"]), it.get("desc", "")]
	if kind == KIND_ARMOR:
		var slot_name: String = AD.SLOT_NAMES.get(str(it.get("slot", "")), "护甲")
		return "[%s][%s]%s %s\n防御 +%s  生命 +%s\n%s" % [
			qn, slot_name, extra, it["name"],
			str(it.get("def_bonus", 0)), str(it.get("hp_bonus", 0)), it.get("desc", "")
		]
	return "%s x%s" % [it["name"], it["qty"]]


func materials_text() -> String:
	var parts: Array = []
	for k in materials:
		var info: Dictionary = WD.SALVAGE[k]
		parts.append("%s×%d" % [info["name"], int(materials[k])])
	return "  ".join(parts)


func armor_slots_text() -> String:
	var parts: Array = []
	for slot in [AD.SLOT_HEAD, AD.SLOT_CHEST, AD.SLOT_TRINKET]:
		var it := get_equipped_armor_item(slot)
		var label: String = AD.SLOT_NAMES.get(slot, slot)
		if it.is_empty():
			parts.append("%s:无" % label)
		else:
			parts.append("%s:%s" % [label, str(it.get("name", ""))])
	return "  ".join(parts)


func to_dict() -> Dictionary:
	var packed_items: Array = []
	for it in items:
		var d: Dictionary = {}
		for k in it:
			var v = it[k]
			if v is Color:
				d[k] = {"__color": true, "r": v.r, "g": v.g, "b": v.b, "a": v.a}
			else:
				d[k] = v
		packed_items.append(d)
	return {
		"uid": _uid,
		"equipped_weapon_uid": equipped_weapon_uid,
		"equipped_armor": equipped_armor.duplicate(true),
		"materials": materials.duplicate(true),
		"items": packed_items,
	}


func from_dict(data: Dictionary) -> void:
	if data.is_empty():
		return
	_uid = int(data.get("uid", 0))
	equipped_weapon_uid = int(data.get("equipped_weapon_uid", 0))
	var ea = data.get("equipped_armor", {})
	if ea is Dictionary:
		for slot in equipped_armor:
			equipped_armor[slot] = int(ea.get(slot, -1))
	var mats = data.get("materials", {})
	if mats is Dictionary:
		for k in mats:
			materials[k] = int(mats[k])
	items.clear()
	var raw_items = data.get("items", [])
	if raw_items is Array:
		for raw in raw_items:
			if raw is not Dictionary:
				continue
			var it: Dictionary = {}
			for k in raw:
				var v = raw[k]
				if v is Dictionary and bool(v.get("__color", false)):
					it[k] = Color(float(v.get("r", 1)), float(v.get("g", 1)), float(v.get("b", 1)), float(v.get("a", 1)))
				else:
					it[k] = v
			items.append(it)
	inventory_changed.emit()
	material_changed.emit()
	equipment_changed.emit("weapon", str(get_equipped_item().get("name", "")))
