class_name QuestGuide
extends Node3D
## 任务目标光柱 / 叹号，挂在当前要打的怪头顶。

var beam: MeshInstance3D
var mark: Label3D
var target: Node3D = null
var _t: float = 0.0


func _ready() -> void:
	beam = MeshInstance3D.new()
	beam.name = "Beam"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.15
	cyl.bottom_radius = 0.35
	cyl.height = 8.0
	beam.mesh = cyl
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = Color(1.0, 0.85, 0.2, 0.35)
	bmat.emission_enabled = true
	bmat.emission = Color(1.0, 0.8, 0.15)
	bmat.emission_energy_multiplier = 1.2
	bmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bmat.cull_mode = BaseMaterial3D.CULL_DISABLED
	beam.material_override = bmat
	beam.position = Vector3(0, 4.0, 0)
	beam.visible = false
	add_child(beam)

	mark = Label3D.new()
	mark.name = "Mark"
	mark.text = "!"
	mark.font_size = 64
	mark.outline_size = 10
	mark.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	mark.modulate = Color(1.0, 0.85, 0.1)
	mark.position = Vector3(0, 2.4, 0)
	mark.visible = false
	add_child(mark)


func set_target(t: Node3D) -> void:
	target = t
	var on := t != null and is_instance_valid(t)
	if beam:
		beam.visible = on
	if mark:
		mark.visible = on


func _process(delta: float) -> void:
	if target == null or not is_instance_valid(target):
		set_target(null)
		return
	if target.has_method("is_alive") and not target.is_alive():
		set_target(null)
		return
	global_position = target.global_position
	_t += delta
	if beam:
		beam.rotation.y += delta * 1.2
		var pulse := 1.0 + sin(_t * 4.0) * 0.08
		beam.scale = Vector3(pulse, 1.0, pulse)
	if mark:
		mark.position.y = 2.4 + sin(_t * 3.0) * 0.12
