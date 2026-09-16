class_name ArmorData
extends RefCounted
## 护甲：头/胸/饰品。品质复用 WeaponData，数值以防御/生命为主。

const WD := preload("res://wow/data/WeaponData.gd")

const SLOT_HEAD := "head"
const SLOT_CHEST := "chest"
const SLOT_TRINKET := "trinket"

const SLOT_NAMES := {
	SLOT_HEAD: "头部",
	SLOT_CHEST: "胸甲",
	SLOT_TRINKET: "饰品",
}

## 模板
const ARMOR_BASES := {
	"leather_helm": {
		"slot": SLOT_HEAD,
		"display_name": "皮革头盔",
		"base_def": 2.0,
		"base_hp": 5.0,
		"desc": "粗糙但实用的防护",
	},
	"iron_helm": {
		"slot": SLOT_HEAD,
		"display_name": "铁铸战盔",
		"base_def": 5.0,
		"base_hp": 15.0,
		"desc": "部落制式头盔",
	},
	"storm_helm": {
		"slot": SLOT_HEAD,
		"display_name": "雷纹战盔",
		"base_def": 9.0,
		"base_hp": 30.0,
		"desc": "蜥蜴守护的雷纹冠盔",
	},
	"hide_chest": {
		"slot": SLOT_CHEST,
		"display_name": "兽皮胸甲",
		"base_def": 3.0,
		"base_hp": 10.0,
		"desc": "坚韧兽皮缝制",
	},
	"orc_chest": {
		"slot": SLOT_CHEST,
		"display_name": "兽人重甲",
		"base_def": 7.0,
		"base_hp": 25.0,
		"desc": "厚重板甲，抗打击",
	},
	"blood_chest": {
		"slot": SLOT_CHEST,
		"display_name": "血吼战甲",
		"base_def": 14.0,
		"base_hp": 60.0,
		"desc": "督军亲卫甲胄",
	},
	"bone_ring": {
		"slot": SLOT_TRINKET,
		"display_name": "兽骨指环",
		"base_def": 1.0,
		"base_hp": 8.0,
		"desc": "荒野猎手的护身符",
	},
	"storm_ring": {
		"slot": SLOT_TRINKET,
		"display_name": "风暴护符",
		"base_def": 4.0,
		"base_hp": 20.0,
		"desc": "内含微弱雷纹",
	},
	"warlord_core_charm": {
		"slot": SLOT_TRINKET,
		"display_name": "督军徽记",
		"base_def": 8.0,
		"base_hp": 40.0,
		"desc": "格罗玛什亲授徽记",
	},
}

## 掉落：怪物类型 -> [{base, weight, q}]
const DROP_TABLE := {
	"boar": [
		{"base": "leather_helm", "weight": 0.18, "q": {"common": 0.80, "uncommon": 0.20, "rare": 0.0, "epic": 0.0}},
	],
	"scorpion": [
		{"base": "hide_chest", "weight": 0.20, "q": {"common": 0.70, "uncommon": 0.28, "rare": 0.02, "epic": 0.0}},
	],
	"raptor": [
		{"base": "bone_ring", "weight": 0.18, "q": {"common": 0.60, "uncommon": 0.32, "rare": 0.08, "epic": 0.0}},
	],
	"beast": [
		{"base": "hide_chest", "weight": 0.18, "q": {"common": 0.55, "uncommon": 0.35, "rare": 0.10, "epic": 0.0}},
	],
	"kolkar": [
		{"base": "iron_helm", "weight": 0.16, "q": {"common": 0.50, "uncommon": 0.38, "rare": 0.12, "epic": 0.0}},
		{"base": "orc_chest", "weight": 0.14, "q": {"common": 0.45, "uncommon": 0.38, "rare": 0.15, "epic": 0.02}},
	],
	"harpy": [
		{"base": "storm_ring", "weight": 0.18, "q": {"common": 0.30, "uncommon": 0.40, "rare": 0.25, "epic": 0.05}},
	],
	"lizard": [
		{"base": "storm_helm", "weight": 0.16, "q": {"common": 0.20, "uncommon": 0.35, "rare": 0.35, "epic": 0.10}},
	],
	"boss": [
		{"base": "blood_chest", "weight": 0.55, "q": {"common": 0.0, "uncommon": 0.0, "rare": 0.40, "epic": 0.60}},
		{"base": "warlord_core_charm", "weight": 0.45, "q": {"common": 0.0, "uncommon": 0.0, "rare": 0.35, "epic": 0.65}},
	],
}

const ELITE_QUALITY_BOOST := 0.25
const ENHANCE_DEF_PER_LEVEL := 1.0
const ENHANCE_HP_PER_LEVEL := 4.0
const ENHANCE_MAX_LEVEL := 10
const ENHANCE_COST_PER_LEVEL := {
	"iron_shard": 2,
	"magic_shard": 1,
}

## 品质加成（在基础值上乘）
const QUALITY_DEF_MULT := {
	"common": 1.0, "uncommon": 1.5, "rare": 2.2, "epic": 3.2,
}


static func calc_def(base_id: String, quality: String, enhance_level: int) -> float:
	var b: Dictionary = ARMOR_BASES.get(base_id, {})
	var base: float = float(b.get("base_def", 0.0))
	var mult: float = float(QUALITY_DEF_MULT.get(quality, 1.0))
	return round(base * mult + enhance_level * ENHANCE_DEF_PER_LEVEL)


static func calc_hp(base_id: String, quality: String, enhance_level: int) -> float:
	var b: Dictionary = ARMOR_BASES.get(base_id, {})
	var base: float = float(b.get("base_hp", 0.0))
	var mult: float = float(QUALITY_DEF_MULT.get(quality, 1.0))
	return round(base * mult + enhance_level * ENHANCE_HP_PER_LEVEL)


static func make_armor_instance(base_id: String, quality: String, enhance_level: int = 0) -> Dictionary:
	var b: Dictionary = ARMOR_BASES.get(base_id, ARMOR_BASES["leather_helm"])
	var qcol: Color = WD.quality_color(quality)
	var name := "%s·%s" % [WD.quality_name(quality), str(b["display_name"])]
	if enhance_level > 0:
		name += " +%d" % enhance_level
	return {
		"id": base_id,
		"kind": "armor",
		"slot": str(b["slot"]),
		"quality": quality,
		"enhance": enhance_level,
		"name": name,
		"qty": 1,
		"def_bonus": calc_def(base_id, quality, enhance_level),
		"hp_bonus": calc_hp(base_id, quality, enhance_level),
		"color": Color(0.45, 0.5, 0.55).lerp(qcol, 0.35),
		"desc": str(b["desc"]),
	}


static func roll_drop(type_id: String, elite: bool = false) -> Dictionary:
	if not DROP_TABLE.has(type_id):
		return {}
	var table: Array = DROP_TABLE[type_id]
	var total_w := 0.0
	for e in table:
		total_w += float(e["weight"])
	if total_w <= 0.0:
		return {}
	var drop_p := minf(total_w, 1.0)
	if randf() > drop_p:
		return {}
	var roll := randf() * total_w
	var acc := 0.0
	var picked: Dictionary = {}
	for e in table:
		acc += float(e["weight"])
		if roll <= acc:
			picked = e
			break
	if picked.is_empty():
		picked = table[table.size() - 1]
	var quality := _roll_quality(picked["q"], elite)
	return make_armor_instance(str(picked["base"]), quality, 0)


static func _roll_quality(qw: Dictionary, elite: bool) -> String:
	var w_common := float(qw.get("common", 0.5))
	var w_uncommon := float(qw.get("uncommon", 0.3))
	var w_rare := float(qw.get("rare", 0.15))
	var w_epic := float(qw.get("epic", 0.05))
	if elite:
		var take: float = minf(w_common, WD.ELITE_QUALITY_BOOST)
		w_common -= take
		w_uncommon += take * 0.35
		w_rare += take * 0.40
		w_epic += take * 0.25
	var total := w_common + w_uncommon + w_rare + w_epic
	if total <= 0.0:
		return "common"
	var r := randf() * total
	if r < w_common:
		return "common"
	r -= w_common
	if r < w_uncommon:
		return "uncommon"
	r -= w_uncommon
	if r < w_rare:
		return "rare"
	return "epic"


static func enhance_cost(level: int) -> Dictionary:
	var mult := 1 + int(level / 3)
	var out := {}
	for k in ENHANCE_COST_PER_LEVEL:
		out[k] = int(ENHANCE_COST_PER_LEVEL[k]) * mult
	return out


static func sell_value(quality: String, enhance_level: int) -> Dictionary:
	## 卖出返还部分材料
	var salvage := WD.decompose_yield(quality)
	var out := {}
	for k in salvage:
		out[k] = maxi(int(salvage[k]) / 2, 1)
	if enhance_level > 0:
		out["iron_shard"] = int(out.get("iron_shard", 0)) + enhance_level
	return out
