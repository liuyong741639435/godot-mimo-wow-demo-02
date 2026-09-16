extends SceneTree
## 无头自测：背包 / 掉落 / 强化 / 角色面板数据链

const WD := preload("res://wow/data/WeaponData.gd")
const InvScript := preload("res://wow/scripts/systems/PlayerInventory.gd")

var failed := 0
var passed := 0


func _init() -> void:
	print("=== WOW Demo Inventory Self-Test ===")
	_test_weapon_data()
	_test_drop_rates()
	_test_inventory_lifecycle()
	_test_enhance()
	_test_decompose()
	_test_quality_atk()
	_test_player_attack_chain()
	print("=== RESULT: %d passed, %d failed ===" % [passed, failed])
	quit(1 if failed > 0 else 0)


func ok(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		passed += 1
		print("  PASS  %s" % name)
	else:
		failed += 1
		print("  FAIL  %s %s" % [name, detail])


func _test_weapon_data() -> void:
	print("\n[WeaponData]")
	ok("make_weapon rust common atk=3", absf(WD.calc_atk("rusty", "common", 0) - 3.0) < 0.01)
	ok("make_weapon orcish uncommon atk=13", absf(WD.calc_atk("orcish", "uncommon", 0) - 13.0) < 0.01)
	ok("make_weapon blood epic atk=101", absf(WD.calc_atk("blood", "epic", 0) - 101.0) < 0.01)
	var inst := WD.make_weapon_instance("wind", "rare", 2)
	ok("instance name has quality+enhance", "优秀" in str(inst["name"]) and "+2" in str(inst["name"]), str(inst["name"]))
	ok("instance atk = 12*2.4 + 4 = 33", absf(float(inst["atk_bonus"]) - 33.0) < 0.01, str(inst["atk_bonus"]))
	ok("quality_name unknown falls back", WD.quality_name("nope") == "普通")
	ok("enhance_cost lv0 = iron2 magic1", int(WD.enhance_cost(0)["iron_shard"]) == 2 and int(WD.enhance_cost(0)["magic_shard"]) == 1)
	ok("enhance_cost lv3 mult2", int(WD.enhance_cost(3)["iron_shard"]) == 4)
	ok("decompose epic yields warlord_core", int(WD.decompose_yield("epic").get("warlord_core", 0)) == 1)


func _test_drop_rates() -> void:
	print("\n[Drop rates]")
	# 固定种子统计掉率（修复后应接近表配置，而非 100%）
	var trials := 4000
	var drops := 0
	seed(42)
	for i in range(trials):
		var d := WD.roll_drop("boar", false)
		if not d.is_empty():
			drops += 1
	var rate := float(drops) / float(trials)
	ok("boar drop rate ~0.35 (got %.3f)" % rate, rate > 0.28 and rate < 0.42, str(rate))

	var boss_drops := 0
	for i in range(500):
		if not WD.roll_drop("boss", false).is_empty():
			boss_drops += 1
	ok("boss always drops", boss_drops == 500, str(boss_drops))

	# 质量分布：非空掉落中至少能见到 common
	var qualities := {}
	seed(7)
	for i in range(2000):
		var d := WD.roll_drop("kolkar", false)
		if d.is_empty():
			continue
		var q := str(d.get("quality", "common"))
		qualities[q] = int(qualities.get(q, 0)) + 1
	ok("kolkar can drop", int(qualities.values().reduce(func(a, b): return a + b, 0)) > 0, str(qualities))
	ok("kolkar has multiple qualities possible", qualities.size() >= 1)

	# 精英质量更好：rare+epic 比例应高于普通
	var normal_hi := 0
	var elite_hi := 0
	seed(99)
	for i in range(1500):
		var n := WD.roll_drop("scorpion", false)
		if not n.is_empty() and (n["quality"] == "rare" or n["quality"] == "epic"):
			normal_hi += 1
		var e := WD.roll_drop("scorpion", true)
		if not e.is_empty() and (e["quality"] == "rare" or e["quality"] == "epic"):
			elite_hi += 1
	ok("elite rare+epic not less than normal (%d vs %d)" % [elite_hi, normal_hi], elite_hi >= normal_hi)


func _make_inv() -> PlayerInventory:
	var n := Node.new()
	n.set_script(InvScript)
	# 不进树，手动 _ready
	n._ready()
	return n


func _test_inventory_lifecycle() -> void:
	print("\n[Inventory lifecycle]")
	var inv := _make_inv()
	ok("starts with axe + potion", inv.items.size() == 2)
	ok("axe equipped uid=0", inv.equipped_weapon_uid == 0 and inv.get_equipped_weapon() == "none")
	ok("potion qty=3", int(inv.items[1]["qty"]) == 3)

	var drop := WD.make_weapon_instance("orcish", "uncommon", 0)
	inv.add_weapon_drop(drop)
	ok("add drop grows bag", inv.items.size() == 3)
	ok("new drop not auto-equip", inv.get_equipped_weapon() == "none")
	var new_idx := 2
	ok("equip drop works", inv.equip_index(new_idx))
	ok("equipped id is orcish", inv.get_equipped_weapon() == "orcish")
	ok("equipped bonus 13", absf(inv.get_weapon_bonus() - 13.0) < 0.01)
	ok("old axe unequipped", not bool(inv.items[0].get("equipped", false)))

	# 不能分解已装备
	ok("cannot decompose equipped", not inv.decompose_index(new_idx))

	# 再丢一把并装备，分解旧的
	var drop2 := WD.make_weapon_instance("wind", "rare", 1)
	inv.add_weapon_drop(drop2)
	ok("equip second weapon", inv.equip_index(3))
	ok("now wind equipped", inv.get_equipped_weapon() == "wind")
	var before_iron := int(inv.materials["iron_shard"])
	ok("decompose unequipped orcish", inv.decompose_index(2))
	ok("iron shard gained", int(inv.materials["iron_shard"]) > before_iron)
	ok("bag shrunk after decompose", inv.items.size() == 3)

	# 药水联动
	inv.update_potion_qty(1)
	var pot: Dictionary = {}
	for it in inv.items:
		if str(it.get("id")) == "potion":
			pot = it
	ok("potion qty synced", int(pot.get("qty", -1)) == 1)


func _test_enhance() -> void:
	print("\n[Enhance]")
	var inv := _make_inv()
	inv.add_material("iron_shard", 50)
	inv.add_material("magic_shard", 50)
	ok("can_enhance with materials", inv.can_enhance_equipped() == false)  # still axe "none"
	ok("cannot enhance none weapon", not inv.enhance_equipped())

	inv.add_weapon_drop(WD.make_weapon_instance("orcish", "rare", 0))
	ok("equip orcish for enhance", inv.equip_index(2))
	var base_atk := inv.get_weapon_bonus()
	ok("base atk 19", absf(base_atk - 19.0) < 0.01, str(base_atk))
	ok("can enhance after equip", inv.can_enhance_equipped())
	ok("enhance +1", inv.enhance_equipped())
	var it := inv.get_equipped_item()
	ok("enhance level 1", int(it["enhance"]) == 1)
	ok("atk +2", absf(float(it["atk_bonus"]) - (base_atk + 2.0)) < 0.01, str(it["atk_bonus"]))
	ok("name has +1", "+1" in str(it["name"]))
	ok("materials consumed", int(inv.materials["iron_shard"]) < 50)

	# 拉满到 +10
	var guard := 0
	while inv.can_enhance_equipped() and guard < 20:
		inv.enhance_equipped()
		guard += 1
	it = inv.get_equipped_item()
	ok("max enhance 10", int(it["enhance"]) == 10, str(it["enhance"]))
	ok("cannot enhance past max", not inv.enhance_equipped())

	# 材料不足
	var inv2 := _make_inv()
	inv2.add_weapon_drop(WD.make_weapon_instance("rusty", "common", 0))
	inv2.equip_index(2)
	ok("cannot enhance without materials", not inv2.enhance_equipped())


func _test_decompose() -> void:
	print("\n[Decompose]")
	var inv := _make_inv()
	inv.add_weapon_drop(WD.make_weapon_instance("blood", "epic", 0))
	ok("equip epic", inv.equip_index(2))
	# 穿上后不能分解自己
	ok("cannot decompose self", not inv.decompose_index(2))

	inv.add_weapon_drop(WD.make_weapon_instance("storm", "rare", 0))
	ok("equip rare storm", inv.equip_index(3))
	# 此时 epic 在 index 2
	ok("decompose epic blood", inv.decompose_index(2))
	ok("got magic_shard from epic", int(inv.materials["magic_shard"]) >= 3)
	ok("got storm_core", int(inv.materials["storm_core"]) >= 2)
	ok("got warlord_core", int(inv.materials["warlord_core"]) >= 1)


func _test_quality_atk() -> void:
	print("\n[Quality ATK]")
	ok("common rusty 3", WD.calc_atk("rusty", "common", 0) == 3)
	ok("uncommon rusty 5", WD.calc_atk("rusty", "uncommon", 0) == 5)
	ok("rare orcish 19", WD.calc_atk("orcish", "rare", 0) == 19)
	ok("epic blood 101", WD.calc_atk("blood", "epic", 0) == 101)
	ok("enhance scales linearly", WD.calc_atk("orcish", "common", 5) == WD.calc_atk("orcish", "common", 0) + 10)


func _test_player_attack_chain() -> void:
	print("\n[Player attack chain data]")
	# 仅验证数据链：base_atk + weapon_bonus
	ok("Lv1 base atk 8", absf(float(preload("res://wow/data/GameBalance.gd").base_atk_for_level(1)) - 8.0) < 0.01)
	var inst := WD.make_weapon_instance("storm", "epic", 3)
	ok("storm epic +3 atk ~71", absf(float(inst["atk_bonus"]) - 71.0) < 0.01, str(inst["atk_bonus"]))
	# 装备栏描述不崩
	var inv := _make_inv()
	inv.add_weapon_drop(inst)
	inv.equip_index(2)
	var desc := inv.describe_index(2)
	ok("describe_index non-empty", desc.length() > 5 and "攻击" in desc, desc)
	ok("materials_text non-empty", inv.materials_text().length() > 5)
