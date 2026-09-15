class_name PlayerHUD
extends CanvasLayer
const GB := preload("res://wow/data/GameBalance.gd")
## Player HUD bindings. Resolve nodes in bind_player (UI is built after attach).

var hp_bar: ProgressBar
var rage_bar: ProgressBar
var exp_bar: ProgressBar
var hp_text: Label
var rage_text: Label
var exp_text: Label
var level_label: Label
var combat_label: Label
var potion_label: Label
var potion_cd_label: Label
var target_frame: Control
var target_name: Label
var target_hp: Label
var target_hp_bar: ProgressBar
var toast_label: Label
var _skill_slots: Dictionary = {}
var _player_level: int = 1


func bind_player(p: Node) -> void:
	if p == null:
		return
	_resolve_ui()
	p.stats.health_changed.connect(_on_health)
	p.stats.rage_changed.connect(_on_rage)
	p.stats.exp_changed.connect(_on_exp)
	p.stats.combat_state_changed.connect(_on_combat)
	p.stats.potion_count_changed.connect(_on_potion_count)
	p.stats.potion_cooldown_changed.connect(_on_potion_cd)
	p.stats.level_up.connect(_on_level)
	if p.has_node("SkillController"):
		p.skills.cooldown_updated.connect(_on_skill_cd)
	_on_health(p.stats.hp, p.stats.max_hp)
	_on_rage(p.stats.rage, GB.RAGE_MAX)
	_on_exp(p.stats.exp, p.stats.get_exp_needed(), p.stats.level)
	_on_combat(p.stats.in_combat)
	_on_potion_count(p.stats.potion_count)
	_player_level = p.stats.level
	if level_label:
		level_label.text = "兽人战士 Lv%d" % _player_level
	_refresh_skill_locks()


func _resolve_ui() -> void:
	hp_bar = _find_by_name("HPBar") as ProgressBar
	rage_bar = _find_by_name("RageBar") as ProgressBar
	exp_bar = _find_by_name("ExpBar") as ProgressBar
	hp_text = _find_by_name("HPText") as Label
	rage_text = _find_by_name("RageText") as Label
	exp_text = _find_by_name("ExpText") as Label
	level_label = _find_by_name("LevelLabel") as Label
	combat_label = _find_by_name("CombatLabel") as Label
	potion_label = _find_by_name("PotionLabel") as Label
	potion_cd_label = _find_by_name("PotionCdLabel") as Label
	target_frame = _find_by_name("TargetFrame") as Control
	target_name = _find_by_name("TargetName") as Label
	target_hp = _find_by_name("TargetHp") as Label
	target_hp_bar = _find_by_name("TargetHpBar") as ProgressBar
	toast_label = _find_by_name("ToastLabel") as Label
	_skill_slots.clear()
	for id in ["heroic", "charge", "intercept", "whirlwind", "potion"]:
		var slot := _find_by_name("SkillSlot_%s" % id)
		if slot:
			_skill_slots[id] = {
				"cd": slot.get_node_or_null("CdOverlay"),
				"cd_text": slot.get_node_or_null("CdText"),
				"lock": slot.get_node_or_null("LockOverlay"),
			}


func show_toast(text: String, color: Color = Color(1, 0.9, 0.4)) -> void:
	if toast_label == null:
		_resolve_ui()
	if toast_label == null:
		return
	toast_label.text = text
	toast_label.add_theme_color_override("font_color", color)
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.5)
	tw.tween_callback(func() -> void: toast_label.visible = false)


func _on_skill_cd(id: StringName, remain: float, total: float) -> void:
	var key := String(id)
	if not _skill_slots.has(key):
		return
	var s: Dictionary = _skill_slots[key]
	if remain <= 0.0:
		if s["cd"]:
			s["cd"].visible = false
		if s["cd_text"]:
			s["cd_text"].text = ""
		return
	if s["cd"]:
		s["cd"].visible = true
		# 自上而下扫过的冷却遮罩
		var ratio := 1.0
		if total > 0.0:
			ratio = clampf(remain / total, 0.0, 1.0)
		if s["cd"] is ProgressBar:
			(s["cd"] as ProgressBar).value = ratio
	if s["cd_text"]:
		s["cd_text"].text = "%.0f" % ceil(remain)


func _on_level(level: int) -> void:
	_player_level = level
	if level_label:
		level_label.text = "兽人战士 Lv%d" % level
	_refresh_skill_locks()
	if level == 3:
		show_toast("解锁技能：拦截 (R→3)", Color(1, 0.5, 0.3))
	elif level == 5:
		show_toast("解锁技能：旋风斩 (4)", Color(1, 0.4, 0.2))
	else:
		show_toast("升级！Lv%d" % level, Color(1, 0.85, 0.3))


func _refresh_skill_locks() -> void:
	var unlock := {
		"heroic": 1, "charge": 1, "potion": 1,
		"intercept": GB.INTERCEPT_UNLOCK_LEVEL,
		"whirlwind": GB.WHIRLWIND_UNLOCK_LEVEL,
	}
	for id in _skill_slots:
		var need: int = unlock.get(id, 1)
		var locked: bool = _player_level < need
		var s: Dictionary = _skill_slots[id]
		if s["lock"]:
			s["lock"].visible = locked
			if locked and s["lock"].get_child_count() > 0:
				var lb := s["lock"].get_child(0) as Label
				if lb:
					lb.text = "Lv%d" % need



func _find_by_name(node_name: String) -> Node:
	var stack: Array = [self]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n.name == node_name:
			return n
		for c in n.get_children():
			stack.push_back(c)
	return null


func show_target(target: Node) -> void:
	if target_frame == null:
		_resolve_ui()
	if target_frame == null:
		return
	if target == null:
		target_frame.visible = false
		return
	target_frame.visible = true
	if target_name:
		var n := "目标"
		if target.get("display_name") != null:
			n = str(target.display_name)
		target_name.text = n
	if target.get("hp") != null and target.get("max_hp") != null:
		if target_hp_bar:
			target_hp_bar.max_value = target.max_hp
			target_hp_bar.value = target.hp
		if target_hp:
			target_hp.text = "%d / %d" % [int(target.hp), int(target.max_hp)]


func _on_health(current: float, max_value: float) -> void:
	if hp_bar:
		hp_bar.max_value = max_value
		hp_bar.value = current
	if hp_text:
		hp_text.text = "%d / %d" % [int(current), int(max_value)]


func _on_rage(current: float, max_value: float) -> void:
	if rage_bar:
		rage_bar.max_value = max_value
		rage_bar.value = current
	if rage_text:
		rage_text.text = "%d / %d" % [int(current), int(max_value)]


func _on_exp(current: int, needed: int, level: int) -> void:
	if level_label:
		level_label.text = "兽人战士 Lv%d" % level
	if level >= GB.PLAYER_LEVEL_MAX:
		if exp_bar:
			exp_bar.max_value = 1
			exp_bar.value = 1
		if exp_text:
			exp_text.text = "已满级"
		return
	if exp_bar:
		exp_bar.max_value = needed
		exp_bar.value = current
	if exp_text:
		exp_text.text = "%d / %d" % [current, needed]


func _on_combat(in_combat: bool) -> void:
	if combat_label == null:
		return
	if in_combat:
		combat_label.text = "战斗中"
		combat_label.add_theme_color_override("font_color", Color(1, 0.35, 0.3))
	else:
		combat_label.text = "脱离战斗"
		combat_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4))


func _on_potion_count(count: int) -> void:
	if potion_label:
		potion_label.text = "x%d" % count


func _on_potion_cd(remain: float, _total: float) -> void:
	if potion_cd_label == null:
		return
	if remain <= 0.0:
		potion_cd_label.text = ""
	else:
		potion_cd_label.text = "%.1f" % remain
