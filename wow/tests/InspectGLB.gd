extends SceneTree
## 检查 Bestiary GLB 的节点/动画结构


func _initialize() -> void:
	_inspect("res://wow/assets/monsters/Imp/Imp.glb")
	_inspect("res://wow/assets/monsters/Puglin/Puglin.glb")
	quit(0)


func _inspect(path: String) -> void:
	print("\n=== ", path, " ===")
	var packed := load(path)
	if packed == null:
		print("  LOAD FAILED")
		return
	print("  type=", packed.get_class())
	if packed is PackedScene:
		var root: Node = (packed as PackedScene).instantiate()
		_dump(root, 0)
		# animations
		var ap := _find_anim_player(root)
		if ap:
			print("  AnimationPlayer anims=", ap.get_animation_list())
		else:
			print("  no AnimationPlayer")
		root.free()
	else:
		print("  not a PackedScene")


func _dump(n: Node, depth: int) -> void:
	if depth > 6:
		return
	var pad := ""
	for i in range(depth):
		pad += "  "
	var extra := ""
	if n is MeshInstance3D:
		var m: MeshInstance3D = n
		if m.mesh:
			extra = " mesh=%s" % m.mesh.get_class()
	if n is Skeleton3D:
		var sk: Skeleton3D = n
		extra = " bones=%d" % sk.get_bone_count()
	print("%s%s (%s)%s" % [pad, n.name, n.get_class(), extra])
	for c in n.get_children():
		_dump(c, depth + 1)


func _find_anim_player(n: Node) -> AnimationPlayer:
	if n is AnimationPlayer:
		return n
	for c in n.get_children():
		var r := _find_anim_player(c)
		if r:
			return r
	return null
