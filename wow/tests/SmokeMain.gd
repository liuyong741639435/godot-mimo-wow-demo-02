extends SceneTree
## 冒烟：加载 Main，验证背包/角色面板/掉落进包

const WD := preload("res://wow/data/WeaponData.gd")

var failed := 0


func _initialize() -> void:
	_run()


func _run() -> void:
	print("=== Main scene smoke ===")
	var packed := load("res://wow/scenes/Main.tscn")
	if packed == null:
		_fail("load Main.tscn")
		quit(1)
		return
	var scene: Node = packed.instantiate()
	root.add_child(scene)
	# 等几帧让 @onready / process_frame bind 跑完
	for i in range(4):
		await process_frame

	var player := scene.get_node_or_null("Player")
	var inv := scene.get_node_or_null("Inventory")
	var inv_ui := scene.get_node_or_null("InventoryUI")
	var hud := scene.get_node_or_null("HUD")

	_check("player exists", player != null)
	_check("inventory exists", inv != null)
	_check("inventory_ui exists", inv_ui != null)
	_check("hud exists", hud != null)

	if player and inv and inv_ui:
		_check("player.inventory bound", player.get("inventory") == inv)
		_check("inv has items", inv.items.size() >= 2)
		_check("inv_ui.inv bound", inv_ui.get("inv") == inv)
		_check("inv_ui.player bound", inv_ui.get("player") == player)
		var stats = inv_ui.get("_stats")
		_check("char panel has level", stats is Dictionary and stats.has("level"))
		_check("char panel has weapon", stats is Dictionary and stats.has("weapon"))
		var eq_label: Label = inv_ui.get("_eq_label")
		_check("eq label shows axe", eq_label != null and "战斧" in eq_label.text, str(eq_label.text if eq_label else ""))

		var before: int = inv.items.size()
		var drop := WD.make_weapon_instance("orcish", "uncommon", 0)
		inv.add_weapon_drop(drop)
		_check("drop added to bag", inv.items.size() == before + 1)
		_check("equip from bag", inv.equip_index(inv.items.size() - 1))
		if player.has_method("equip_from_item"):
			player.equip_from_item(inv.get_equipped_item())
		_check("player weapon_bonus updated", absf(float(player.get("weapon_bonus_atk")) - 13.0) < 0.01, str(player.get("weapon_bonus_atk")))
		_check("total atk = base+bonus", absf(float(player.get_total_attack()) - (8.0 + 13.0)) < 0.01, str(player.get_total_attack()))

		inv.add_material("iron_shard", 20)
		inv.add_material("magic_shard", 20)
		_check("enhance equipped", inv.enhance_equipped())
		player.equip_from_item(inv.get_equipped_item())
		_check("bonus after +1", absf(float(player.get("weapon_bonus_atk")) - 15.0) < 0.01, str(player.get("weapon_bonus_atk")))

		if inv_ui.has_method("_refresh_stats"):
			inv_ui._refresh_stats()
		var st2 = inv_ui.get("_stats")
		if st2 is Dictionary and st2.has("weapon"):
			var wlabel: Label = st2["weapon"]
			_check("char weapon label updated", wlabel.text.length() > 0, wlabel.text)

	_check("toggle_bag registered", InputMap.has_action("toggle_bag"))
	_check("toggle_char registered", InputMap.has_action("toggle_char"))

	print("=== smoke done, failed=%d ===" % failed)
	quit(1 if failed > 0 else 0)


func _check(name: String, cond: bool, detail: String = "") -> void:
	if cond:
		print("  PASS  %s" % name)
	else:
		_fail(name, detail)


func _fail(name: String, detail: String = "") -> void:
	failed += 1
	print("  FAIL  %s %s" % [name, detail])
