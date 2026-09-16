class_name WeaponData
extends RefCounted
## 武器/品质/掉落/分解/强化

## 品质
const QUALITY_COMMON := "common"
const QUALITY_UNCOMMON := "uncommon"
const QUALITY_RARE := "rare"
const QUALITY_EPIC := "epic"

const QUALITY_INFO := {
	QUALITY_COMMON: {"name": "普通", "color": Color(0.75, 0.75, 0.75), "atk_mult": 1.0},
	QUALITY_UNCOMMON: {"name": "优良", "color": Color(0.3, 0.85, 0.35), "atk_mult": 1.6},
	QUALITY_RARE: {"name": "优秀", "color": Color(0.35, 0.6, 1.0), "atk_mult": 2.4},
	QUALITY_EPIC: {"name": "史诗", "color": Color(0.7, 0.35, 1.0), "atk_mult": 3.6},
}

## 基础剑模板（显示名/色/描述/基础atk）
const SWORD_BASES := {
	"rusty": {
		"display_name": "锈蚀长剑",
		"base_atk": 3.0,
		"color": Color(0.55, 0.42, 0.32),
		"vfx_color": Color(0.8, 0.7, 0.5),
		"scale": 1.05,
		"desc": "半人马常用的破旧长剑",
	},
	"orcish": {
		"display_name": "兽人重剑",
		"base_atk": 8.0,
		"color": Color(0.45, 0.48, 0.52),
		"vfx_color": Color(1.0, 0.55, 0.2),
		"scale": 1.15,
		"desc": "厚重刃身，力量型挥砍",
	},
	"wind": {
		"display_name": "风怒之刃",
		"base_atk": 12.0,
		"color": Color(0.55, 0.75, 0.85),
		"vfx_color": Color(0.4, 0.85, 1.0),
		"scale": 1.1,
		"desc": "鹰身人秘宝，攻击带风痕",
	},
	"storm": {
		"display_name": "雷霆战剑",
		"base_atk": 18.0,
		"color": Color(0.35, 0.55, 0.75),
		"vfx_color": Color(0.6, 0.8, 1.0),
		"scale": 1.2,
		"desc": "蜥蜴守护的雷纹长剑",
	},
	"blood": {
		"display_name": "血吼之刃",
		"base_atk": 28.0,
		"color": Color(0.7, 0.18, 0.15),
		"vfx_color": Color(1.0, 0.25, 0.15),
		"scale": 1.3,
		"desc": "督军佩剑，霸气外露",
	},
}

## 兼容旧接口（无品质id）
const SWORDS := {
	"none": {
		"display_name": "战斧",
		"atk_bonus": 0.0,
		"color": Color(0.58, 0.58, 0.62),
		"vfx_color": Color(1, 0.95, 0.7),
		"scale": 1.0,
		"desc": "初始武器",
	},
}

## 掉落：type -> [ {base, weight, quality_weights} ]
## quality_weights: common/uncommon/rare/epic
const DROP_TABLE := {
	"boar": [
		{"base": "rusty", "weight": 0.35, "q": {"common": 0.85, "uncommon": 0.15, "rare": 0.0, "epic": 0.0}},
	],
	"scorpion": [
		{"base": "rusty", "weight": 0.40, "q": {"common": 0.70, "uncommon": 0.28, "rare": 0.02, "epic": 0.0}},
	],
	"raptor": [
		{"base": "orcish", "weight": 0.35, "q": {"common": 0.55, "uncommon": 0.35, "rare": 0.10, "epic": 0.0}},
	],
	"beast": [
		{"base": "orcish", "weight": 0.35, "q": {"common": 0.45, "uncommon": 0.38, "rare": 0.15, "epic": 0.02}},
	],
	"kolkar": [
		{"base": "rusty", "weight": 0.25, "q": {"common": 0.50, "uncommon": 0.40, "rare": 0.10, "epic": 0.0}},
		{"base": "orcish", "weight": 0.30, "q": {"common": 0.40, "uncommon": 0.40, "rare": 0.18, "epic": 0.02}},
	],
	"harpy": [
		{"base": "wind", "weight": 0.32, "q": {"common": 0.30, "uncommon": 0.40, "rare": 0.25, "epic": 0.05}},
	],
	"lizard": [
		{"base": "storm", "weight": 0.28, "q": {"common": 0.20, "uncommon": 0.35, "rare": 0.35, "epic": 0.10}},
	],
	"boss": [
		{"base": "blood", "weight": 1.0, "q": {"common": 0.0, "uncommon": 0.0, "rare": 0.35, "epic": 0.65}},
	],
}

## 精英额外品质偏移（向高质量倾斜）
const ELITE_QUALITY_BOOST := 0.25

## 分解材料
## 破损铁片 / 魔化碎片 / 雷纹结晶 / 督军之核
const SALVAGE := {
	"iron_shard": {"name": "破损铁片", "color": Color(0.7, 0.7, 0.7)},
	"magic_shard": {"name": "魔化碎片", "color": Color(0.35, 0.9, 0.4)},
	"storm_core": {"name": "雷纹结晶", "color": Color(0.4, 0.7, 1.0)},
	"warlord_core": {"name": "督军之核", "color": Color(0.8, 0.3, 1.0)},
}

## 品质 -> 分解产物
const DECOMPOSE_YIELD := {
	QUALITY_COMMON: {"iron_shard": 2},
	QUALITY_UNCOMMON: {"iron_shard": 3, "magic_shard": 1},
	QUALITY_RARE: {"iron_shard": 2, "magic_shard": 2, "storm_core": 1},
	QUALITY_EPIC: {"magic_shard": 3, "storm_core": 2, "warlord_core": 1},
}

## 强化：每级 +atk，消耗材料
const ENHANCE_COST_PER_LEVEL := {
	"iron_shard": 2,
	"magic_shard": 1,
}
const ENHANCE_ATK_PER_LEVEL := 2.0
const ENHANCE_MAX_LEVEL := 10


static func quality_name(q: String) -> String:
	return str(QUALITY_INFO.get(q, QUALITY_INFO[QUALITY_COMMON])["name"])


static func quality_color(q: String) -> Color:
	return QUALITY_INFO.get(q, QUALITY_INFO[QUALITY_COMMON])["color"]


static func quality_atk_mult(q: String) -> float:
	return float(QUALITY_INFO.get(q, QUALITY_INFO[QUALITY_COMMON])["atk_mult"])


static func get_weapon(id: String) -> Dictionary:
	if SWORDS.has(id):
		return SWORDS[id]
	if SWORD_BASES.has(id):
		var b: Dictionary = SWORD_BASES[id]
		return {
			"display_name": b["display_name"],
			"atk_bonus": b["base_atk"],
			"color": b["color"],
			"vfx_color": b["vfx_color"],
			"scale": b["scale"],
			"desc": b["desc"],
		}
	return SWORDS["none"]


static func calc_atk(base_id: String, quality: String, enhance_level: int) -> float:
	var b: Dictionary = SWORD_BASES.get(base_id, {})
	var base: float = float(b.get("base_atk", 3.0)) if not b.is_empty() else 0.0
	return round(base * quality_atk_mult(quality) + enhance_level * ENHANCE_ATK_PER_LEVEL)


static func make_weapon_instance(base_id: String, quality: String, enhance_level: int = 0) -> Dictionary:
	var b: Dictionary = SWORD_BASES.get(base_id, SWORD_BASES["rusty"])
	var qcol: Color = quality_color(quality)
	var name := "%s·%s" % [quality_name(quality), str(b["display_name"])]
	if enhance_level > 0:
		name += " +%d" % enhance_level
	return {
		"id": base_id,
		"kind": "weapon",
		"quality": quality,
		"enhance": enhance_level,
		"name": name,
		"qty": 1,
		"atk_bonus": calc_atk(base_id, quality, enhance_level),
		"color": b["color"].lerp(qcol, 0.35),
		"vfx": b["vfx_color"],
		"scale": float(b["scale"]),
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
	var base_id: String = str(picked["base"])
	var quality := _roll_quality(picked["q"], elite)
	return make_weapon_instance(base_id, quality, 0)


static func _roll_quality(qw: Dictionary, elite: bool) -> String:
	var w_common := float(qw.get("common", 0.5))
	var w_uncommon := float(qw.get("uncommon", 0.3))
	var w_rare := float(qw.get("rare", 0.15))
	var w_epic := float(qw.get("epic", 0.05))
	if elite:
		# 精英：把部分普通权重挪给高质量
		var shift := ELITE_QUALITY_BOOST
		var take: float = minf(w_common, shift)
		w_common -= take
		w_uncommon += take * 0.35
		w_rare += take * 0.40
		w_epic += take * 0.25
	var total := w_common + w_uncommon + w_rare + w_epic
	if total <= 0.0:
		return QUALITY_COMMON
	var r := randf() * total
	if r < w_common:
		return QUALITY_COMMON
	r -= w_common
	if r < w_uncommon:
		return QUALITY_UNCOMMON
	r -= w_uncommon
	if r < w_rare:
		return QUALITY_RARE
	return QUALITY_EPIC


static func decompose_yield(quality: String) -> Dictionary:
	return DECOMPOSE_YIELD.get(quality, DECOMPOSE_YIELD[QUALITY_COMMON])


static func enhance_cost(level: int) -> Dictionary:
	var mult := 1 + int(level / 3)
	var out := {}
	for k in ENHANCE_COST_PER_LEVEL:
		out[k] = int(ENHANCE_COST_PER_LEVEL[k]) * mult
	return out
