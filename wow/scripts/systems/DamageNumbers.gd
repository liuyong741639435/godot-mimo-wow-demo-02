class_name DamageNumbers
extends Node3D
## Floating combat text above targets.

const _LABEL_SCRIPT := """
extends Label3D
var _vel: Vector3 = Vector3.ZERO
var _life: float = 0.0

func _process(delta: float) -> void:
	_life -= delta
	position += _vel * delta
	_vel.y = lerpf(_vel.y, 0.5, delta * 2.0)
	modulate.a = clampf(_life / 0.8, 0.0, 1.0)
	if _life <= 0.0:
		queue_free()
"""


static func spawn(parent: Node, world_pos: Vector3, text: String, color: Color) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var scene := parent.get_tree().current_scene
	if scene == null:
		scene = parent
	var lab := Label3D.new()
	lab.text = text
	lab.modulate = color
	lab.font_size = 36
	lab.outline_size = 8
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.no_depth_test = true
	lab.position = world_pos + Vector3(randf_range(-0.2, 0.2), 1.6, randf_range(-0.2, 0.2))
	scene.add_child(lab)
	var s := GDScript.new()
	s.source_code = _LABEL_SCRIPT
	s.reload()
	lab.set_script(s)
	lab.set("_vel", Vector3(randf_range(-0.5, 0.5), 2.2, randf_range(-0.3, 0.3)))
	lab.set("_life", 0.85)


static func player_damage(parent: Node, pos: Vector3, amount: float) -> void:
	spawn(parent, pos, str(int(round(amount))), Color(1.0, 0.85, 0.2))


static func enemy_damage(parent: Node, pos: Vector3, amount: float, crit: bool = false) -> void:
	if crit:
		spawn(parent, pos, str(int(round(amount))) + "!", Color(1.0, 0.4, 0.15))
	else:
		spawn(parent, pos, str(int(round(amount))), Color(1, 1, 1))


static func heal_number(parent: Node, pos: Vector3, amount: float) -> void:
	spawn(parent, pos, "+" + str(int(round(amount))), Color(0.35, 1.0, 0.4))
