class_name VfxLibrary
extends RefCounted
## Spawn short-lived VFX bursts.

const ParticleScript := preload("res://wow/scripts/systems/VfxParticle.gd")


static func slash(parent: Node, origin: Vector3, color: Color = Color(1, 0.95, 0.7)) -> void:
	_burst(parent, origin + Vector3(0, 1.1, 0), color, 10, 0.28, 3.2)


static func hit_spark(parent: Node, origin: Vector3, color: Color = Color(1, 0.5, 0.2)) -> void:
	_burst(parent, origin + Vector3(0, 1.0, 0), color, 12, 0.2, 3.5)


static func charge_trail(parent: Node, origin: Vector3) -> void:
	_burst(parent, origin + Vector3(0, 0.9, 0), Color(0.6, 0.8, 1), 16, 0.35, 2.5)


static func whirlwind(parent: Node, origin: Vector3) -> void:
	for i in range(12):
		var ang := TAU * float(i) / 12.0
		var pos := origin + Vector3(cos(ang) * 1.4, 0.5 + float(i % 3) * 0.25, sin(ang) * 1.4)
		_burst(parent, pos, Color(0.95, 0.85, 0.45), 3, 0.4, 4.0)


static func heal_spark(parent: Node, origin: Vector3) -> void:
	_burst(parent, origin + Vector3(0, 0.4, 0), Color(0.3, 1, 0.4), 14, 0.45, 1.5)


static func level_up(parent: Node, origin: Vector3) -> void:
	_burst(parent, origin + Vector3(0, 0.2, 0), Color(1, 0.85, 0.2), 24, 0.7, 3.0)


static func _burst(parent: Node, origin: Vector3, color: Color, count: int, life: float, speed: float) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var scene := parent.get_tree().current_scene
	if scene == null:
		scene = parent
	for i in count:
		var p: Node3D = ParticleScript.new()
		scene.add_child(p)
		p.global_position = origin
		p.setup(color, randf_range(0.05, 0.12))
		p.dir = Vector3(randf_range(-1, 1), randf_range(0.2, 1.2), randf_range(-1, 1)).normalized()
		p.speed = speed * randf_range(0.6, 1.3)
		p.life = life * randf_range(0.7, 1.2)
