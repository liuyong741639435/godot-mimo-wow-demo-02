class_name MerchantUI
extends CanvasLayer
## 营地商人：买药水 / 卖出未装备装备。G 开关。

const GB := preload("res://wow/data/GameBalance.gd")
const WD := preload("res://wow/data/WeaponData.gd")
const AD := preload("res://wow/data/ArmorData.gd")

var inv: PlayerInventory
var player: Node
var open := false
var _root: Control
var _panel: PanelContainer
var _mat_label: Label
var _status: Label
var _sell_list: ItemList
var _bag_list: ItemList


func _ready() -> void:
	layer = 22
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.visible = false
	add_child(_root)
	_build()


func bind(p: Node, inventory: PlayerInventory) -> void:
	player = p
	inv = inventory
	if inv and not inv.inventory_changed.is_connected(_refresh):
		inv.inventory_changed.connect(_refresh)
	if inv and not inv.material_changed.is_connected(_refresh):
		inv.material_changed.connect(_refresh)
	_refresh()


func set_open(on: bool) -> void:
	open = on
	_root.visible = on
	_panel.visible = on
	if on:
		_refresh()


## 不在此处监听输入；由 MainBootstrap 在营地靠近军需官时调用 set_open。


func _panel_style() -> StyleBoxFlat:
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.06, 0.08, 0.1, 0.94)
	st.set_corner_radius_all(10)
	st.set_border_width_all(1)
	st.border_color = Color(0.7, 0.55, 0.2)
	st.content_margin_left = 12
	st.content_margin_right = 12
	st.content_margin_top = 10
	st.content_margin_bottom = 10
	return st


func _build() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(640, 480)
	_panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(_panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	_panel.add_child(box)

	var t := Label.new()
	t.text = "军需官·物资交换"
	t.add_theme_font_size_override("font_size", 18)
	box.add_child(t)

	_mat_label = Label.new()
	_mat_label.text = "材料："
	_mat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(_mat_label)

	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 12)
	cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(cols)

	# 左：购买
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(left)
	var lt := Label.new()
	lt.text = "购买"
	left.add_child(lt)
	var buy_info := Label.new()
	buy_info.text = "初级治疗药水\n价格：%s x%d / 瓶\n库存上限随药水栏" % [
		str(WD.SALVAGE["iron_shard"]["name"]), int(GB.POTION_BUY_COST.get("iron_shard", 4))
	]
	buy_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(buy_info)
	var buy_row := HBoxContainer.new()
	left.add_child(buy_row)
	var b1 := Button.new()
	b1.text = "买 1 瓶"
	b1.pressed.connect(func(): _buy(1))
	buy_row.add_child(b1)
	var b5 := Button.new()
	b5.text = "买 5 瓶"
	b5.pressed.connect(func(): _buy(5))
	buy_row.add_child(b5)

	_bag_list = ItemList.new()
	_bag_list.custom_minimum_size = Vector2(280, 180)
	_bag_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_bag_list)
	_bag_list.item_selected.connect(func(i: int) -> void:
		if inv:
			_status.text = inv.describe_index(i)
	)

	# 右：卖出
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols.add_child(right)
	var rt := Label.new()
	rt.text = "卖出（未装备装备）"
	right.add_child(rt)
	_sell_list = ItemList.new()
	_sell_list.custom_minimum_size = Vector2(280, 280)
	_sell_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(_sell_list)
	var sell_btn := Button.new()
	sell_btn.text = "卖出选中"
	sell_btn.pressed.connect(_on_sell)
	right.add_child(sell_btn)

	_status = Label.new()
	_status.text = "选中物品查看详情"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(600, 40)
	box.add_child(_status)

	var bottom := HBoxContainer.new()
	box.add_child(bottom)
	var cl := Button.new()
	cl.text = "关闭(G)"
	cl.pressed.connect(func(): set_open(false))
	bottom.add_child(cl)


func _buy(n: int) -> void:
	if inv == null:
		return
	if inv.buy_potion(n, GB.POTION_BUY_COST):
		if player and player.get("stats"):
			player.stats.potion_count = inv.get_potion_qty()
			player.stats.potion_count_changed.emit(player.stats.potion_count)
		_status.text = "购买成功：药水 x%d" % n
		_refresh()
	else:
		_status.text = "材料不足"


func _on_sell() -> void:
	if inv == null:
		return
	var sel := _sell_list.get_selected_items()
	if sel.is_empty():
		_status.text = "请先选中要卖出的装备"
		return
	var bag_idx = _sell_list.get_item_metadata(sel[0])
	if bag_idx == null:
		_status.text = "选中无效"
		return
	if inv.sell_index(int(bag_idx)):
		_status.text = "已卖出，获得材料"
		_refresh()
	else:
		_status.text = "无法卖出（已装备/类型不符）"


func _refresh() -> void:
	if _mat_label == null or inv == null:
		return
	_mat_label.text = "材料：" + inv.materials_text()
	_bag_list.clear()
	_sell_list.clear()
	for i in range(inv.items.size()):
		var it: Dictionary = inv.items[i]
		var kind := str(it.get("kind", ""))
		var line := ""
		if kind == "weapon" or kind == "armor":
			var q: String = str(it.get("quality", "common"))
			line = "[%s] %s" % [WD.quality_name(q), str(it.get("name", ""))]
			if int(it.get("uid", -1)) == inv.equipped_weapon_uid:
				line += " <<已装备"
			var slot := str(it.get("slot", ""))
			if kind == "armor" and int(inv.equipped_armor.get(slot, -1)) == int(it.get("uid", -1)):
				line += " <<已装备"
			_bag_list.add_item(line)
			_bag_list.set_item_custom_fg_color(_bag_list.item_count - 1, WD.quality_color(q))
			# 可卖出：非已装备
			var equipped := false
			if kind == "weapon":
				equipped = int(it.get("uid", -1)) == inv.equipped_weapon_uid
			elif kind == "armor":
				equipped = int(inv.equipped_armor.get(slot, -1)) == int(it.get("uid", -1))
			if not equipped and str(it.get("id", "")) != "none":
				_sell_list.add_item(line)
				_sell_list.set_item_custom_fg_color(_sell_list.item_count - 1, WD.quality_color(q))
				_sell_list.set_item_metadata(_sell_list.item_count - 1, i)
		else:
			line = "[药] %s x%s" % [it.get("name", ""), it.get("qty", 0)]
			_bag_list.add_item(line)
