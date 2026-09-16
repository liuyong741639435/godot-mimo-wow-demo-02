class_name MonsterModelLibrary
extends RefCounted
## Bestiary GLB 怪物模型：Imp / Puglin，带 3 套配色变体。

const IMP_SCENE := "res://wow/assets/monsters/Imp/Imp.glb"
const PUGLIN_SCENE := "res://wow/assets/monsters/Puglin/Puglin.glb"

## type_id -> {scene, scale, variant, y_offset}
const TYPE_MAP := {
	"boar": {"scene": PUGLIN_SCENE, "scale": 0.85, "variant": 0, "y": 0.0},
	"scorpion": {"scene": PUGLIN_SCENE, "scale": 0.75, "variant": 1, "y": 0.0},
	"raptor": {"scene": PUGLIN_SCENE, "scale": 0.95, "variant": 2, "y": 0.0},
	"beast": {"scene": PUGLIN_SCENE, "scale": 1.0, "variant": 1, "y": 0.0},
	"kolkar": {"scene": IMP_SCENE, "scale": 1.05, "variant": 0, "y": 0.0},
	"harpy": {"scene": IMP_SCENE, "scale": 0.95, "variant": 1, "y": 0.15},
	"lizard": {"scene": IMP_SCENE, "scale": 1.2, "variant": 2, "y": 0.0},
	"boss": {"scene": IMP_SCENE, "scale": 1.55, "variant": 2, "y": 0.0},
}

static func has_model(type_id: String) -> bool:
	return TYPE_MAP.has(type_id)


static func build(parent: Node3D, type_id: String, elite: bool = false) -> bool:
	if parent == null or not TYPE_MAP.has(type_id):
		return false
	var cfg: Dictionary = TYPE_MAP[type_id]
	var packed: PackedScene = load(str(cfg["scene"]))
	if packed == null:
		return false
	var model: Node3D = packed.instantiate()
	model.name = "BestiaryModel"
	var sc: float = float(cfg.get("scale", 1.0))
	if elite:
		sc *= 1.2
	model.scale = Vector3.ONE * sc
	model.position = Vector3(0, float(cfg.get("y", 0.0)), 0)
	parent.add_child(model)
	_apply_variant(model, str(cfg["scene"]), int(cfg.get("variant", 0)))
	return true


static func _apply_variant(model: Node, scene_path: String, variant: int) -> void:
	var is_imp := "Imp" in scene_path
	var tex_name := ""
	if is_imp:
		tex_name = "res://wow/assets/monsters/Imp/T_Imp_BaseColor_%d.png" % clampi(variant + 1, 1, 3)
	else:
		tex_name = "res://wow/assets/monsters/Puglin/T_Puglin_BaseColor_%d.png" % clampi(variant + 1, 1, 3)
	var tex: Texture2D = load(tex_name)
	if tex == null:
		return
	for mesh in _find_meshes(model):
		var mat: Material = mesh.material_override
		if mat is StandardMaterial3D:
			(mat as StandardMaterial3D).albedo_texture = tex
		elif mesh.get_surface_override_material_count() > 0:
			var m0: Material = mesh.get_surface_override_material(0)
			if m0 is StandardMaterial3D:
				(m0 as StandardMaterial3D).albedo_texture = tex
		else:
			var nm := StandardMaterial3D.new()
			nm.albedo_texture = tex
			nm.roughness = 0.85
			mesh.material_override = nm


static func _find_meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_meshes(c))
	return out
