class_name InventoryUI
extends CanvasLayer
## 背包 + 多槽装备 + 角色状态 + 材料/分解/强化
## B 背包，C 角色

const WD := preload("res://wow/data/WeaponData.gd")
const AD := preload("res://wow/data/ArmorData.gd")

var inv: PlayerInventory
var player: Node

var _root: Control
var _bag_panel: Control
var _char_panel: Control
var _bag_list: ItemList
var _desc_label: Label
var _eq_label: Label
var _mat_label: Label
var _cap_label: Label
var _stats: Dictionary = {}
var _show_bag := false
var _show_char := false


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)
	_build_bag()
	_build_char()


func bind(p: Node, inventory: PlayerInventory) -> void:
	player = p
	inv = inventory
	if inv:
		if not inv.inventory_changed.is_connected(_refresh_all):
			inv.inventory_changed.connect(_refresh_all)
		if not inv.equipment_changed.is_connected(_on_equip_changed):
			inv.equipment_changed.connect(_on_equip_changed)
		if not inv.bag_full_rejected.is_connected(_on_bag_full):
			inv.bag_full_rejected.connect(_on_bag_full)
	if player and player.get("stats"):
		var s = player.stats
		s.health_changed.connect(func(_a, _b): _refresh_stats())
		s.rage_changed.connect(func(_a, _b): _refresh_stats())
		s.exp_changed.connect(func(_a, _b, _c): _refresh_stats())
		s.level_up.connect(func(_l): _refresh_stats())
		s.combat_state_changed.connect(func(_c): _refresh_stats())
	_refresh_all()
	_refresh_stats()


func _process(_d: float) -> void:
	if Input.is_action_just_pressed("toggle_bag"):
		_show_bag = not _show_bag
		_bag_panel.visible = _show_bag
		_root.visible = _show_bag or _show_char
		if _show_bag:
			_refresh_all()
	elif Input.is_action_just_pressed("toggle_char"):
		_show_char = not _show_char
		_char_panel.visible = _show_char
		_root.visible = _show_bag or _show_char
		if _show_char:
			_refresh_stats()


func _panel_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.07, 0.07, 0.1, 0.93)
	st.set_corner_radius_all(10)
	st.set_border_width_all(1)
	st.border_color = Color(0.55, 0.45, 0.22)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st


func _build_bag() -> void:
	_bag_panel = PanelContainer.new()
	_bag_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_bag_panel.position = Vector2(50, 40)
	_bag_panel.custom_minimum_size = Vector2(480, 560)
	_bag_panel.add_theme_stylebox_override("panel", _panel_style())
	_bag_panel.visible = false
	_root.add_child(_bag_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	_bag_panel.add_child(box)

	var t := Label.new()
	t.text = "背包 / 装备"
	t.add_theme_font_size_override("font_size", 18)
	box.add_child(t)

	_cap_label = Label.new()
	_cap_label.text = "容量 0/24"
	box.add_child(_cap_label)

	_eq_label = Label.new()
	_eq_label.text = "武器：战斧"
	_eq_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_eq_label)

	_mat_label = Label.new()
	_mat_label.text = "材料：无"
	_mat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_mat_label)

	_bag_list = ItemList.new()
	_bag_list.custom_minimum_size = Vector2(440, 300)
	_bag_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_bag_list)
	_bag_list.item_selected.connect(func(i: int) -> void:
		if inv:
			_desc_label.text = inv.describe_index(i)
	)

	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 8)
	box.add_child(btns)
	var b_eq := Button.new()
	b_eq.text = "装备"
	b_eq.pressed.connect(_on_equip)
	btns.add_child(b_eq)
	var b_dec := Button.new()
	b_dec.text = "分解"
	b_dec.pressed.connect(_on_decompose)
	btns.add_child(b_dec)
	var b_up := Button.new()
	b_up.text = "强化选中/已装备"
	b_up.pressed.connect(_on_enhance)
	btns.add_child(b_up)
	var b_cl := Button.new()
	b_cl.text = "关闭(B)"
	b_cl.pressed.connect(func() -> void:
		_show_bag = false
		_bag_panel.visible = false
		_root.visible = _show_char
	)
	btns.add_child(b_cl)

	_desc_label = Label.new()
	_desc_label.text = "选中物品查看详情"
	_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc_label.custom_minimum_size = Vector2(440, 64)
	box.add_child(_desc_label)


func _build_char() -> void:
	_char_panel = PanelContainer.new()
	_char_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_char_panel.position = Vector2(560, 60)
	_char_panel.custom_minimum_size = Vector2(360, 460)
	_char_panel.add_theme_stylebox_override("panel", _panel_style())
	_char_panel.visible = false
	_root.add_child(_char_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	_char_panel.add_child(box)
	var t := Label.new()
	t.text = "角色状态"
	t.add_theme_font_size_override("font_size", 18)
	box.add_child(t)
	_stats["name"] = _row(box, "角色", "兽人战士")
	_stats["level"] = _row(box, "等级", "Lv1")
	_stats["hp"] = _row(box, "生命", "100/100")
	_stats["rage"] = _row(box, "怒气", "0/100")
	_stats["exp"] = _row(box, "经验", "0/80")
	_stats["atk"] = _row(box, "攻击", "8")
	_stats["def"] = _row(box, "防御", "0")
	_stats["dr"] = _row(box, "减伤", "0%")
	_stats["weapon"] = _row(box, "武器", "战斧")
	_stats["head"] = _row(box, "头部", "无")
	_stats["chest"] = _row(box, "胸甲", "无")
	_stats["trinket"] = _row(box, "饰品", "无")
	_stats["quality"] = _row(box, "武器品质", "普通")
	_stats["enhance"] = _row(box, "武器强化", "+0")
	_stats["combat"] = _row(box, "状态", "脱战")
	var b := Button.new()
	b.text = "关闭(C)"
	b.pressed.connect(func() -> void:
		_show_char = false
		_char_panel.visible = false
		_root.visible = _show_bag
	)
	box.add_child(b)


func _row(parent: VBoxContainer, k: String, v: String) -> Label:
	var h := HBoxContainer.new()
	parent.add_child(h)
	var kl := Label.new()
	kl.text = k
	kl.custom_minimum_size = Vector2(72, 0)
	h.add_child(kl)
	var vl := Label.new()
	vl.text = v
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vl)
	return vl


func _on_bag_full(item_name: String) -> void:
	_desc_label.text = "背包已满，无法拾取：%s" % item_name


func _on_equip() -> void:
	if inv == null:
		return
	var sel := _bag_list.get_selected_items()
	if sel.is_empty():
		_desc_label.text = "请先选中装备"
		return
	if inv.equip_index(sel[0]):
		var it: Dictionary = inv.get_equipped_item()
		if player and player.has_method("equip_from_item") and not it.is_empty() and it.get("kind") == "weapon":
			player.equip_from_item(it)
		if player and player.has_method("refresh_armor_max_hp"):
			player.refresh_armor_max_hp()
		_desc_label.text = "已装备 " + str(inv.items[sel[0]].get("name", ""))
		_refresh_all()
		_refresh_stats()


func _on_decompose() -> void:
	if inv == null:
		return
	var sel := _bag_list.get_selected_items()
	if sel.is_empty():
		_desc_label.text = "请先选中要分解的装备"
		return
	var idx: int = sel[0]
	if idx < 0 or idx >= inv.items.size():
		return
	var it: Dictionary = inv.items[idx]
	var kind := str(it.get("kind", ""))
	if kind != "weapon" and kind != "armor":
		_desc_label.text = "只能分解武器/护甲"
		return
	if str(it.get("id", "")) == "none":
		_desc_label.text = "不能分解初始武器"
		return
	var q: String = str(it.get("quality", "common"))
	if inv.decompose_index(idx):
		_desc_label.text = "已分解 [%s]，获得材料" % WD.quality_name(q)
		_refresh_all()
		_refresh_stats()
	else:
		_desc_label.text = "无法分解（可能已装备）"


func _on_enhance() -> void:
	if inv == null:
		return
	var uid := inv.equipped_weapon_uid
	var sel := _bag_list.get_selected_items()
	if not sel.is_empty() and sel[0] < inv.items.size():
		var it: Dictionary = inv.items[sel[0]]
		var kind := str(it.get("kind", ""))
		if kind == "weapon" or kind == "armor":
			uid = int(it.get("uid", -1))
	if inv.enhance_item_uid(uid):
		var name := ""
		for it2 in inv.items:
			if int(it2.get("uid", -1)) == uid:
				name = str(it2.get("name", ""))
				break
		if player and player.has_method("equip_from_item") and uid == inv.equipped_weapon_uid:
			player.equip_from_item(inv.get_equipped_item())
		if player and player.has_method("refresh_armor_max_hp"):
			player.refresh_armor_max_hp()
		_desc_label.text = "强化成功：%s" % name
		_refresh_all()
		_refresh_stats()
	else:
		_desc_label.text = "材料不足或已达上限"


func _on_equip_changed(_slot: String, _name: String) -> void:
	_refresh_all()
	_refresh_stats()


func _item_line(it: Dictionary) -> String:
	var kind := str(it.get("kind", ""))
	var q: String = str(it.get("quality", "common"))
	var en: int = int(it.get("enhance", 0))
	if kind == "consumable":
		return "[药] %s x%s" % [it.get("name", ""), it.get("qty", 0)]
	var extra := ""
	if en > 0:
		extra = "+%d " % en
	if kind == "weapon":
		var line := "[%s]%s %s" % [WD.quality_name(q), extra, str(it.get("name", ""))]
		if int(it.get("uid", -1)) == inv.equipped_weapon_uid:
			line += "  <<已装备"
		return line
	if kind == "armor":
		var slot := str(it.get("slot", ""))
		var sn: String = AD.SLOT_NAMES.get(slot, "护甲")
		var line2 := "[%s][%s]%s %s" % [WD.quality_name(q), sn, extra, str(it.get("name", ""))]
		if int(inv.equipped_armor.get(slot, -1)) == int(it.get("uid", -1)):
			line2 += "  <<已装备"
		return line2
	return str(it.get("name", ""))


func _refresh_all() -> void:
	if _bag_list == null or inv == null:
		return
	_bag_list.clear()
	for it in inv.items:
		_bag_list.add_item(_item_line(it))
	for i in range(_bag_list.item_count):
		var it: Dictionary = inv.items[i]
		var kind := str(it.get("kind", ""))
		if kind == "weapon" or kind == "armor":
			_bag_list.set_item_custom_fg_color(i, WD.quality_color(str(it.get("quality", "common"))))
	_eq_label.text = "武器：" + str(inv.get_equipped_item().get("name", "无")) + "\n" + inv.armor_slots_text()
	_mat_label.text = "材料：" + inv.materials_text()
	if _cap_label:
		_cap_label.text = "容量 %d/%d" % [inv.equipment_slot_count(), inv.BAG_CAPACITY]


func _refresh_stats() -> void:
	if player == null or _stats.is_empty():
		return
	var s = player.get("stats")
	if s == null:
		return
	_stats["level"].text = "Lv%d" % int(s.level)
	_stats["hp"].text = "%d/%d" % [int(s.hp), int(s.max_hp)]
	_stats["rage"].text = "%d/%d" % [int(s.rage), 100]
	var need: int = 0
	if s.has_method("get_exp_needed"):
		need = int(s.get_exp_needed())
	_stats["exp"].text = "%d/%d" % [int(s.exp), need]
	var atk: float = 0.0
	if player.has_method("get_total_attack"):
		atk = float(player.get_total_attack())
	_stats["atk"].text = str(int(atk))
	var def := 0.0
	var dr := 0.0
	if player.has_method("get_armor_defense"):
		def = float(player.get_armor_defense())
	if player.has_method("get_damage_reduction"):
		dr = float(player.get_damage_reduction())
	_stats["def"].text = str(int(def))
	_stats["dr"].text = "%d%%" % int(dr * 100.0)
	if inv:
		var it: Dictionary = inv.get_equipped_item()
		_stats["weapon"].text = str(it.get("name", "战斧"))
		_stats["quality"].text = WD.quality_name(str(it.get("quality", "common")))
		var en: int = int(it.get("enhance", 0))
		_stats["enhance"].text = "+%d" % en
		for slot in ["head", "chest", "trinket"]:
			var ait: Dictionary = inv.get_equipped_armor_item(slot)
			_stats[slot].text = "无" if ait.is_empty() else str(ait.get("name", ""))
	_stats["combat"].text = "战斗中" if s.in_combat else "脱战"
