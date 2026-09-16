extends SceneTree
## 扩展自测：护甲槽 / 商人买卖 / 存档 / 模型库

const WD := preload("res://wow/data/WeaponData.gd")
const AD := preload("res://wow/data/ArmorData.gd")
const InvScript := preload("res://wow/scripts/systems/PlayerInventory.gd")
const SaveSystem := preload("res://wow/scripts/systems/SaveSystem.gd")
const Models := preload("res://wow/scripts/systems/MonsterModelLibrary.gd")

var failed := 0
var passed := 0


func _init() -> void:
	print("=== Expansion Self-Test ===")
	_test_armor_data()
	_test_armor_equip()
	_test_bag_capacity()
	_test_merchant_buy_sell()
	_test_save_roundtrip()
	_test_model_map()
	print("=== RESULT: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func ok(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		passed += 1
		print("  PASS  %s" % name)
	else:
		failed += 1
		print("  FAIL  %s %s" % [name, detail])


func _make_inv() -> PlayerInventory:
	var n := Node.new()
	n.set_script(InvScript)
	n._ready()
	return n


func _test_armor_data() -> void:
	print("\n[ArmorData]")
	var a := AD.make_armor_instance("orc_chest", "rare", 2)
	ok("armor kind", a["kind"] == "armor")
	ok("armor slot chest", a["slot"] == "chest")
	ok("armor name quality", "优秀" in str(a["name"]) and "+2" in str(a["name"]), str(a["name"]))
	ok("armor def>0", float(a["def_bonus"]) > 0, str(a["def_bonus"]))
	ok("armor hp>0", float(a["hp_bonus"]) > 0, str(a["hp_bonus"]))
	seed(3)
	var hits := 0
	for i in range(800):
		if not AD.roll_drop("kolkar", false).is_empty():
			hits += 1
	ok("kolkar armor drop not always", hits > 0 and hits < 800, str(hits))
	var sell := AD.sell_value("rare", 2)
	ok("sell has iron", int(sell.get("iron_shard", 0)) >= 1, str(sell))


func _test_armor_equip() -> void:
	print("\n[Armor equip]")
	var inv := _make_inv()
	ok("add armor", inv.add_armor_drop(AD.make_armor_instance("iron_helm", "uncommon", 0)))
	ok("equip helm", inv.equip_index(2))
	ok("head equipped uid", int(inv.equipped_armor["head"]) == int(inv.items[2]["uid"]))
	ok("def bonus >0", inv.get_armor_def_bonus() > 0)
	ok("hp bonus >0", inv.get_armor_hp_bonus() > 0)
	inv.add_armor_drop(AD.make_armor_instance("hide_chest", "common", 0))
	ok("equip chest", inv.equip_index(3))
	ok("two slots", inv.get_armor_def_bonus() > 1.0)
	# 不能分解已装备
	ok("cannot decomp equipped armor", not inv.decompose_index(2))
	inv.add_armor_drop(AD.make_armor_instance("bone_ring", "common", 0))
	ok("equip trinket", inv.equip_index(4))
	ok("three slots", inv.armor_slots_text().contains("头部") and inv.armor_slots_text().contains("饰品"))
	# 强化护甲
	inv.add_material("iron_shard", 30)
	inv.add_material("magic_shard", 30)
	var uid := int(inv.items[2]["uid"])
	var before_def := float(inv.items[2]["def_bonus"])
	ok("enhance armor", inv.enhance_item_uid(uid))
	ok("def increased", float(inv.items[2]["def_bonus"]) > before_def)


func _test_bag_capacity() -> void:
	print("\n[Bag capacity]")
	var inv := _make_inv()
	ok("capacity 24", inv.BAG_CAPACITY == 24)
	ok("not full at start", not inv.is_bag_full())
	for i in range(30):
		inv.add_weapon_drop(WD.make_weapon_instance("rusty", "common", 0))
	ok("cannot exceed capacity", inv.equipment_slot_count() <= inv.BAG_CAPACITY, str(inv.equipment_slot_count()))


func _test_merchant_buy_sell() -> void:
	print("\n[Merchant]")
	var inv := _make_inv()
	ok("buy fail no mats", not inv.buy_potion(1, {"iron_shard": 4}))
	inv.add_material("iron_shard", 20)
	var potions_before := inv.get_potion_qty()
	ok("buy 1 potion", inv.buy_potion(1, {"iron_shard": 4}))
	ok("potion +1", inv.get_potion_qty() == potions_before + 1)
	ok("iron spent", int(inv.materials["iron_shard"]) == 16)
	inv.add_weapon_drop(WD.make_weapon_instance("orcish", "uncommon", 0))
	var iron_before := int(inv.materials["iron_shard"])
	ok("sell unequipped", inv.sell_index(2))
	ok("got materials", int(inv.materials["iron_shard"]) > iron_before)
	ok("cannot sell equipped", not inv.sell_index(0))


func _test_save_roundtrip() -> void:
	print("\n[Save roundtrip]")
	var inv := _make_inv()
	inv.add_weapon_drop(WD.make_weapon_instance("blood", "epic", 3))
	inv.equip_index(2)
	inv.add_armor_drop(AD.make_armor_instance("storm_helm", "rare", 1))
	inv.equip_index(3)
	inv.add_material("warlord_core", 5)
	var d := inv.to_dict()
	var inv2 := _make_inv()
	inv2.from_dict(d)
	ok("items restored", inv2.items.size() == inv.items.size(), "%d vs %d" % [inv2.items.size(), inv.items.size()])
	ok("weapon equipped", inv2.get_equipped_weapon() == "blood")
	ok("enhance restored", int(inv2.get_equipped_item().get("enhance", 0)) == 3)
	ok("armor equipped", not inv2.get_equipped_armor_item("head").is_empty())
	ok("materials restored", int(inv2.materials["warlord_core"]) == 5)
	# color 序列化
	var col = inv2.items[2].get("color")
	ok("color roundtrip", col is Color, str(col))


func _test_model_map() -> void:
	print("\n[Model map]")
	ok("has imp/puglin map", Models.has_model("boar") and Models.has_model("harpy"))
	ok("no map for unknown", not Models.has_model("dragon"))
	# 资源能加载
	ok("imp scene loads", load(Models.IMP_SCENE) != null)
	ok("puglin scene loads", load(Models.PUGLIN_SCENE) != null)
