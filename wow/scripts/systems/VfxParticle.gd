class_name VfxParticle
extends Node3D
## Single short-lived VFX particle mover.

var dir: Vector3 = Vector3.UP
var speed: float = 2.0
var life: float = 0.3
var _t: float = 0.0
var _mesh: MeshInstance3D


func setup(color: Color, size: float) -> void:
	_mesh = MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size, size, size)
	_mesh.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 2.0
	_mesh.material_override = mat
	add_child(_mesh)


func _process(delta: float) -> void:
	_t += delta
	var k := clampf(_t / maxf(life, 0.01), 0.0, 1.0)
	position += dir * speed * delta
	if _mesh:
		_mesh.scale = Vector3.ONE * maxf(1.0 - k, 0.01)
	if k >= 1.0:
		queue_free()
