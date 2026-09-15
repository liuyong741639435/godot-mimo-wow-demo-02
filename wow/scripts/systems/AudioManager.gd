class_name AudioManager
extends RefCounted
## Thin wrapper: AudioManager.play(parent, kind, volume_db)

const Sfx := preload("res://wow/scripts/systems/SfxLibrary.gd")


static func play(parent: Node, kind: String, volume_db: float = -6.0) -> void:
	Sfx.play_at(parent, _pos(parent), kind, volume_db)


static func _pos(parent: Node) -> Vector3:
	if parent is Node3D:
		return (parent as Node3D).global_position
	return Vector3.ZERO
