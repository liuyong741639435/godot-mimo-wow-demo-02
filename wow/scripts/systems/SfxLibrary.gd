class_name SfxLibrary
extends RefCounted
## Procedural short SFX via AudioStreamGenerator-free approach: use simple tones via AudioStreamWAV.
## Generates tiny PCM buffers at runtime.

static var _cache: Dictionary = {}


static func play_at(parent: Node, pos: Vector3, kind: String, volume_db: float = -6.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var stream := _get_stream(kind)
	if stream == null:
		return
	var p := AudioStreamPlayer3D.new()
	p.stream = stream
	p.volume_db = volume_db
	p.unit_size = 12.0
	parent.add_child(p)
	p.global_position = pos
	p.finished.connect(p.queue_free)
	p.play()


static func play_ui(kind: String, volume_db: float = -4.0) -> void:
	# attach to root via current scene if possible - skip if no tree
	pass


static func _get_stream(kind: String) -> AudioStreamWAV:
	if _cache.has(kind):
		return _cache[kind]
	var data := _gen(kind)
	if data.is_empty():
		return null
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 22050
	s.stereo = false
	s.data = data
	_cache[kind] = s
	return s


static func _gen(kind: String) -> PackedByteArray:
	var samples: PackedFloat32Array = PackedFloat32Array()
	match kind:
		"swing", "slash":
			samples = _tone_sweep(0.08, 800, 200, 0.4)
		"hit":
			samples = _noise(0.06, 0.5)
			_mix_add(samples, _tone_sweep(0.06, 180, 80, 0.5))
		"heavy":
			samples = _tone_sweep(0.15, 220, 60, 0.7)
			_mix_add(samples, _noise(0.08, 0.3))
		"charge":
			samples = _tone_sweep(0.25, 300, 900, 0.35)
		"whirl":
			samples = _tone_sweep(0.5, 400, 150, 0.3)
		"potion":
			samples = _tone_sweep(0.2, 500, 800, 0.25)
		"levelup":
			samples = _tone_sweep(0.15, 523, 784, 0.4)
			_mix_add(samples, _tone_sweep(0.15, 659, 1046, 0.35))
		"quest":
			samples = _tone_sweep(0.12, 660, 990, 0.35)
		"hurt":
			samples = _tone_sweep(0.1, 200, 120, 0.45)
		"enemy_die":
			samples = _tone_sweep(0.2, 300, 80, 0.4)
			_mix_add(samples, _noise(0.12, 0.25))
		"jump":
			samples = _tone_sweep(0.08, 250, 400, 0.25)
		"land":
			samples = _noise(0.07, 0.35)
		_:
			samples = _noise(0.05, 0.2)
	return _f32_to_pcm16(samples)


static func _tone_sweep(dur: float, f0: float, f1: float, vol: float) -> PackedFloat32Array:
	var n := int(22050 * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / float(n)
		var f := lerpf(f0, f1, t)
		phase += TAU * f / 22050.0
		var env := (1.0 - t) * vol
		out[i] = sin(phase) * env
	return out


static func _noise(dur: float, vol: float) -> PackedFloat32Array:
	var n := int(22050 * dur)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / float(n)
		out[i] = randf_range(-1.0, 1.0) * vol * (1.0 - t)
	return out


static func _mix_add(dst: PackedFloat32Array, src: PackedFloat32Array) -> void:
	var n := mini(dst.size(), src.size())
	for i in n:
		dst[i] = clampf(dst[i] + src[i], -1.0, 1.0)


static func _f32_to_pcm16(samples: PackedFloat32Array) -> PackedByteArray:
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		var v := int(clampf(samples[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2] = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	return bytes
