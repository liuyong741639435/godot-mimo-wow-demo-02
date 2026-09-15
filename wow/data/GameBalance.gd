extends RefCounted
## 全局平衡数值。preload 后使用：const GB = preload("res://wow/data/GameBalance.gd")

# --- 玩家基础 ---
const PLAYER_MAX_HP_LV := {
	1: 100, 2: 120, 3: 145, 4: 170, 5: 200
}
const PLAYER_BASE_ATK_LV := {
	1: 8, 2: 10, 3: 12, 4: 14, 5: 17
}
const PLAYER_EXP_TO_LEVEL := {
	# 累计经验达到该值则升到对应等级
	1: 0, 2: 80, 3: 150, 4: 220, 5: 300
}
const PLAYER_LEVEL_MAX := 5

const PLAYER_MOVE_SPEED := 5.0
const PLAYER_JUMP_VELOCITY := 4.5
const PLAYER_GRAVITY := 18.0
const PLAYER_MELEE_RANGE := 2.5
const PLAYER_ATTACK_INTERVAL := 1.2
const PLAYER_ATTACK_RAGE_GAIN := 8
const PLAYER_HIT_RAGE_GAIN := 5
const PLAYER_CHARGE_RAGE_GAIN := 15

# 脱战 / 回血 / 怒气衰减
const COMBAT_EXIT_DISTANCE := 12.0
const COMBAT_EXIT_DELAY := 5.0
const REGEN_DELAY_AFTER_COMBAT := 5.0
const REGEN_PERCENT_PER_SEC := 0.03
const RAGE_MAX := 100.0
const RAGE_DECAY_DELAY := 3.0
const RAGE_DECAY_PER_SEC := 3.0

# 药水
const POTION_COUNT_INIT := 3
const POTION_HEAL_AMOUNT := 40.0
const POTION_COOLDOWN := 20.0

# 技能
const HEROIC_RAGE_COST := 15.0
const HEROIC_COOLDOWN := 2.0
const HEROIC_DAMAGE_MULT := 1.8

const CHARGE_COOLDOWN := 12.0
const CHARGE_MAX_DISTANCE := 8.0
const CHARGE_DAMAGE := 12.0
const CHARGE_STUN_TIME := 0.5

const INTERCEPT_RAGE_COST := 20.0
const INTERCEPT_COOLDOWN := 8.0
const INTERCEPT_MAX_DISTANCE := 15.0
const INTERCEPT_DAMAGE_MULT := 1.5
const INTERCEPT_UNLOCK_LEVEL := 3

const WHIRLWIND_RAGE_COST := 30.0
const WHIRLWIND_COOLDOWN := 10.0
const WHIRLWIND_RADIUS := 3.0
const WHIRLWIND_DAMAGE_MULT := 1.2
const WHIRLWIND_UNLOCK_LEVEL := 5

# 怪物通用
const ENEMY_PATROL_SPEED := 2.0
const ENEMY_CHASE_SPEED := 4.0
const ENEMY_DETECT_RANGE := 5.0
const ENEMY_ATTACK_RANGE := 2.0
const ENEMY_ATTACK_INTERVAL := 2.0
const ENEMY_LEASH_RANGE := 12.0
const ENEMY_RESPAWN_TIME := 30.0
const ENEMY_CORPSE_TIME := 2.0
## 前期最多同时 1 只怪进战；有旋风斩(Lv5)后可放宽
const ENEMY_MAX_SIMULTANEOUS_AGGRO := 1
## 精英怪：每种 1 只，属性倍率
const ELITE_HP_MULT := 2.8
const ELITE_ATK_MULT := 1.5
const ELITE_EXP_MULT := 2.5
const ELITE_SCALE := 1.35

# 怪物模板
const ENEMY_TYPES := {
	"boar": {
		"display_name": "草原野猪",
		"level": 1,
		"max_hp": 60.0,
		"attack": 5.0,
		"exp": 15,
		"creature_type": "野兽",
		"body_color": Color(0.55, 0.35, 0.22),
		"detect_range": 4.0,
	},
	"scorpion": {
		"display_name": "荒漠蝎子",
		"level": 2,
		"max_hp": 80.0,
		"attack": 7.0,
		"exp": 22,
		"creature_type": "野兽",
		"body_color": Color(0.45, 0.32, 0.18),
		"detect_range": 5.0,
	},
	"raptor": {
		"display_name": "幼年迅猛龙",
		"level": 3,
		"max_hp": 110.0,
		"attack": 9.0,
		"exp": 30,
		"creature_type": "野兽",
		"body_color": Color(0.35, 0.48, 0.28),
		"detect_range": 6.0,
	},
	"beast": {
		"display_name": "沙地野兽",
		"level": 4,
		"max_hp": 140.0,
		"attack": 11.0,
		"exp": 40,
		"creature_type": "野兽",
		"body_color": Color(0.42, 0.30, 0.20),
		"detect_range": 7.0,
	},
}

# 精英怪显示名
const ELITE_NAMES := {
	"boar": "精英·獠牙野猪王",
	"scorpion": "精英·赤尾毒蝎",
	"raptor": "精英·迅猛头领",
	"beast": "精英·沙暴兽王",
}

# 玩家死亡
const PLAYER_RESPAWN_DELAY := 3.0

static func max_hp_for_level(level: int) -> float:
	return float(PLAYER_MAX_HP_LV.get(clampi(level, 1, PLAYER_LEVEL_MAX), 100))

static func base_atk_for_level(level: int) -> float:
	return float(PLAYER_BASE_ATK_LV.get(clampi(level, 1, PLAYER_LEVEL_MAX), 8))

static func exp_needed_for_level(level: int) -> int:
	return int(PLAYER_EXP_TO_LEVEL.get(clampi(level, 1, PLAYER_LEVEL_MAX), 0))

static func level_for_exp(exp: int) -> int:
	var result := 1
	for lv in PLAYER_EXP_TO_LEVEL.keys():
		if exp >= int(PLAYER_EXP_TO_LEVEL[lv]) and lv > result:
			result = int(lv)
	return result
