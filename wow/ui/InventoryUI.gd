class_name InventoryUI
extends CanvasLayer
## 背包 + 装备 + 角色状态 + 材料/分解/强化
## B 打开背包，C 打开角色状态

const WD := preload("res://wow/data/WeaponData.gd")

var inv: PlayerInventory
var player: Node

var _root: Control
var _bag_panel: Control
var _char_panel: Control
var _bag_list: ItemList
var _desc_label: Label
var _eq_label: Label
var _mat_label: Label
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
	_bag_panel.custom_minimum_size = Vector2(460, 520)
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

	_eq_label = Label.new()
	_eq_label.text = "已装备：战斧"
	box.add_child(_eq_label)

	_mat_label = Label.new()
	_mat_label.text = "材料：无"
	_mat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_mat_label)

	_bag_list = ItemList.new()
	_bag_list.custom_minimum_size = Vector2(420, 280)
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
	b_up.text = "强化当前武器"
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
	_desc_label.custom_minimum_size = Vector2(420, 56)
	box.add_child(_desc_label)


func _build_char() -> void:
	_char_panel = PanelContainer.new()
	_char_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_char_panel.position = Vector2(540, 60)
	_char_panel.custom_minimum_size = Vector2(320, 380)
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
	_stats["weapon"] = _row(box, "武器", "战斧")
	_stats["quality"] = _row(box, "品质", "普通")
	_stats["enhance"] = _row(box, "强化", "+0")
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
	kl.custom_minimum_size = Vector2(64, 0)
	h.add_child(kl)
	var vl := Label.new()
	vl.text = v
	vl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(vl)
	return vl


func _on_equip() -> void:
	if inv == null:
		return
	var sel := _bag_list.get_selected_items()
	if sel.is_empty():
		_desc_label.text = "请先选中武器"
		return
	if inv.equip_index(sel[0]):
		var it: Dictionary = inv.get_equipped_item()
		if player and player.has_method("equip_from_item") and not it.is_empty():
			player.equip_from_item(it)
		elif player and player.has_method("equip_weapon"):
			player.equip_weapon(str(it.get("id", "none")))
		_desc_label.text = "已装备 " + str(it.get("name", ""))
		_refresh_all()
		_refresh_stats()


func _on_decompose() -> void:
	if inv == null:
		return
	var sel := _bag_list.get_selected_items()
	if sel.is_empty():
		_desc_label.text = "请先选中要分解的装备"
		return
	# 分解前记录品质提示
	var idx: int = sel[0]
	if idx < 0 or idx >= inv.items.size():
		return
	var it: Dictionary = inv.items[idx]
	if it.get("kind") != "weapon" or it.get("id") == "none":
		_desc_label.text = "只能分解武器"
		return
	if int(it.get("uid", -1)) == inv.equipped_weapon_uid:
		_desc_label.text = "不能分解已装备的武器"
		return
	var q: String = str(it.get("quality", "common"))
	if inv.decompose_index(idx):
		_desc_label.text = "已分解 [%s]，获得材料" % WD.quality_name(q)
		_refresh_all()
		_refresh_stats()


func _on_enhance() -> void:
	if inv == null:
		return
	if inv.enhance_equipped():
		var it: Dictionary = inv.get_equipped_item()
		if player and player.has_method("equip_from_item") and not it.is_empty():
			player.equip_from_item(it)
		_desc_label.text = "强化成功：%s" % str(it.get("name", ""))
		_refresh_all()
		_refresh_stats()
	else:
		_desc_label.text = "材料不足或已达上限"


func _on_equip_changed(_id: String, _name: String) -> void:
	_refresh_all()
	_refresh_stats()


func _refresh_all() -> void:
	if _bag_list == null or inv == null:
		return
	_bag_list.clear()
	for it in inv.items:
		var line := ""
		if it.get("kind") == "weapon":
			var q: String = str(it.get("quality", "common"))
			var en: int = int(it.get("enhance", 0))
			line = "[%s]" % WD.quality_name(q)
			if en > 0:
				line += "+%d " % en
			line += " " + str(it["name"])
			if int(it.get("uid", -1)) == inv.equipped_weapon_uid:
				line += "  <<已装备"
		else:
			line = "[药] %s x%s" % [it["name"], it["qty"]]
		_bag_list.add_item(line)
	# 品质着色
	for i in range(_bag_list.item_count):
		var it: Dictionary = inv.items[i]
		if it.get("kind") == "weapon":
			_bag_list.set_item_custom_fg_color(i, WD.quality_color(str(it.get("quality", "common"))))
	_eq_label.text = "已装备：" + str(inv.get_equipped_item().get("name", "无"))
	_mat_label.text = "材料：" + inv.materials_text()


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
	if inv:
		var it: Dictionary = inv.get_equipped_item()
		_stats["weapon"].text = str(it.get("name", "战斧"))
		_stats["quality"].text = WD.quality_name(str(it.get("quality", "common")))
		var en: int = int(it.get("enhance", 0))
		_stats["enhance"].text = "+%d" % en
	_stats["combat"].text = "战斗中" if s.in_combat else "脱战"
