class_name WeaponData
extends RefCounted
## 长剑定义：属性、颜色、攻击特效风格。

const SWORDS := {
	"none": {
		"display_name": "战斧",
		"atk_bonus": 0.0,
		"color": Color(0.58, 0.58, 0.62),
		"vfx_color": Color(1, 0.95, 0.7),
		"scale": 1.0,
		"desc": "初始武器",
	},
	"rusty": {
		"display_name": "锈蚀长剑",
		"atk_bonus": 3.0,
		"color": Color(0.55, 0.42, 0.32),
		"vfx_color": Color(0.8, 0.7, 0.5),
		"scale": 1.05,
		"desc": "半人马掉落的破旧长剑",
	},
	"orcish": {
		"display_name": "兽人重剑",
		"atk_bonus": 8.0,
		"color": Color(0.45, 0.48, 0.52),
		"vfx_color": Color(1.0, 0.55, 0.2),
		"scale": 1.15,
		"desc": "厚重刃身，力量型挥砍",
	},
	"wind": {
		"display_name": "风怒之刃",
		"atk_bonus": 12.0,
		"color": Color(0.55, 0.75, 0.85),
		"vfx_color": Color(0.4, 0.85, 1.0),
		"scale": 1.1,
		"desc": "鹰身人秘宝，攻击带风痕",
	},
	"storm": {
		"display_name": "雷霆战剑",
		"atk_bonus": 18.0,
		"color": Color(0.35, 0.55, 0.75),
		"vfx_color": Color(0.6, 0.8, 1.0),
		"scale": 1.2,
		"desc": "蜥蜴守护的雷纹长剑",
	},
	"blood": {
		"display_name": "血吼之刃",
		"atk_bonus": 28.0,
		"color": Color(0.7, 0.18, 0.15),
		"vfx_color": Color(1.0, 0.25, 0.15),
		"scale": 1.3,
		"desc": "督军佩剑，霸气外露",
	},
}

## 掉落表：怪物类型 -> [武器id, 概率]
const DROP_TABLE := {
	"kolkar": [["rusty", 0.45], ["orcish", 0.12]],
	"harpy": [["wind", 0.35], ["orcish", 0.15]],
	"lizard": [["storm", 0.30], ["wind", 0.20]],
	"boss": [["blood", 1.0]],
	"beast": [["rusty", 0.08]],
}


static func get_weapon(id: String) -> Dictionary:
	return SWORDS.get(id, SWORDS["none"])


static func roll_drop(type_id: String) -> String:
	if not DROP_TABLE.has(type_id):
		return ""
	var table: Array = DROP_TABLE[type_id]
	for entry in table:
		var wid: String = entry[0]
		var chance: float = float(entry[1])
		if randf() <= chance:
			return wid
	return ""
