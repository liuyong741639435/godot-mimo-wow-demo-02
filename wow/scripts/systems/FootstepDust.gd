class_name FootstepDust
extends RefCounted
## 跑动脚步沙尘


static func puff(parent: Node, pos: Vector3) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	const VFX := preload("res://wow/scripts/systems/VfxLibrary.gd")
	VFX._burst(parent, pos + Vector3(randf_range(-0.15, 0.15), 0.05, randf_range(-0.15, 0.15)), Color(0.75, 0.62, 0.42), 4, 0.35, 1.2)
