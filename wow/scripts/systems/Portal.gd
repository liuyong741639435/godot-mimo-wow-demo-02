class_name Portal
extends Node3D
## 场景传送门：靠近自动切换世界。

signal portal_used(target_world: String)

@export var target_world := "camp"
@export var radius := 2.2
@export var locked_message := "需先完成主线前序任务"

var locked := true
var _cool := 0.0
var _beam: MeshInstance3D


func _ready() -> void:
	_beam = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 1.2
	cyl.height = 5.0
	_beam.mesh = cyl
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.3, 0.7, 1.0, 0.4)
	m.emission_enabled = true
	m.emission = Color(0.2, 0.6, 1.0)
	m.emission_energy_multiplier = 1.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam.material_override = m
	_beam.position = Vector3(0, 2.5, 0)
	add_child(_beam)

	var ring := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 0.9
	tor.outer_radius = 1.2
	ring.mesh = tor
	ring.position = Vector3(0, 0.05, 0)
	ring.material_override = m
	add_child(ring)

	var lab := Label3D.new()
	lab.text = "传送门"
	lab.position = Vector3(0, 5.4, 0)
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 24
	lab.outline_size = 6
	add_child(lab)


func set_locked(v: bool) -> void:
	locked = v
	if _beam:
		var m := _beam.material_override as StandardMaterial3D
		if m:
			if v:
				m.albedo_color = Color(0.4, 0.4, 0.45, 0.35)
				m.emission = Color(0.3, 0.3, 0.35)
			else:
				m.albedo_color = Color(0.3, 0.7, 1.0, 0.4)
				m.emission = Color(0.2, 0.6, 1.0)


func _process(delta: float) -> void:
	_cool = maxf(_cool - delta, 0.0)
	if _beam:
		_beam.rotation.y += delta * 1.5
	if locked or _cool > 0.0:
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.is_empty():
		return
	var p: Node3D = players[0]
	if p.global_position.distance_to(global_position) <= radius:
		_cool = 2.0
		portal_used.emit(target_world)
