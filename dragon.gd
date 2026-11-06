class_name Dragon
extends Control
## Dragón que evoluciona con los aciertos y se entristece con los errores.
## Se dibuja por completo con primitivas de Godot, sin imágenes externas.

const MAX_STAGE := 4
const MAX_SADNESS := 3
const STAGE_NAMES := ["Bebé", "Cría", "Joven", "Adulto", "Legendario"]
const MOOD_NAMES := ["Feliz", "Preocupado", "Triste", "Muy triste"]
const MOOD_COLORS := [Color("7CE38B"), Color("FFD54F"), Color("FFAB66"), Color("7FB6FF")]

var stage := 0
var sadness := 0

var _t := 0.0
var _u := 1.0
var _origin := Vector2.ZERO
var _rot := 0.0
var _sx := 1.0
var _sy := 1.0
var _hop := 0.0
var _pop := 1.0
var _droop := 0.0
var _shake := 0.0
var _particles: Array[Dictionary] = []

var _hop_tween: Tween
var _pop_tween: Tween
var _droop_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_t += delta
	if _shake > 0.0:
		_shake = maxf(_shake - delta, 0.0)
	var alive: Array[Dictionary] = []
	for p: Dictionary in _particles:
		p["life"] = float(p["life"]) - delta
		var pos: Vector2 = p["pos"]
		var vel: Vector2 = p["vel"]
		vel.y += 26.0 * delta
		pos += vel * delta
		p["pos"] = pos
		p["vel"] = vel
		if p["life"] > 0.0:
			alive.append(p)
	_particles = alive
	queue_redraw()


# ---------------------------------------------------------------- Acciones

func celebrate() -> void:
	sadness = 0
	_tween_droop(0.0)
	_spawn_particles("heart", 7)
	_jump()
	queue_redraw()


func make_sad() -> void:
	sadness = mini(sadness + 1, MAX_SADNESS)
	_tween_droop(float(sadness) / float(MAX_SADNESS))
	_shake = 0.7
	queue_redraw()


func grow() -> void:
	if stage >= MAX_STAGE:
		return
	stage += 1
	_pop = 0.55
	_spawn_particles("star", 8)
	if _pop_tween and _pop_tween.is_valid():
		_pop_tween.kill()
	_pop_tween = create_tween()
	_pop_tween.tween_property(self, "_pop", 1.0, 0.55) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	queue_redraw()


func reset() -> void:
	stage = 0
	sadness = 0
	_droop = 0.0
	_hop = 0.0
	_pop = 1.0
	_shake = 0.0
	_particles.clear()
	queue_redraw()


func _jump() -> void:
	if _hop_tween and _hop_tween.is_valid():
		_hop_tween.kill()
	_hop_tween = create_tween()
	_hop_tween.tween_property(self, "_hop", -0.8, 0.18) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hop_tween.tween_property(self, "_hop", 0.0, 0.42) \
		.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _tween_droop(target: float) -> void:
	if _droop_tween and _droop_tween.is_valid():
		_droop_tween.kill()
	_droop_tween = create_tween()
	_droop_tween.tween_property(self, "_droop", target, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _spawn_particles(kind: String, amount: int) -> void:
	var c := size * Vector2(0.5, 0.40)
	if size.x < 8.0 or size.y < 8.0:
		c = Vector2(160, 190)
	for i: int in amount:
		var side := -1.0 if i % 2 == 0 else 1.0
		_particles.append({
			"kind": kind,
			"pos": c + Vector2(side * randf_range(35.0, 85.0), randf_range(-25.0, 20.0)),
			"vel": Vector2(randf_range(-18.0, 18.0), randf_range(-95.0, -50.0)),
			"life": randf_range(0.9, 1.4),
			"size": randf_range(8.0, 14.0),
			"rot": randf_range(-0.4, 0.4),
		})


# ---------------------------------------------------------------- Dibujo

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 4.0 or h < 4.0:
		return

	var sad := float(sadness) / float(MAX_SADNESS)
	_u = minf(w, h) * (0.155 + 0.0105 * float(stage)) * _pop
	var base_y := h * 0.58
	var bob := sin(_t * (2.1 - sad * 0.6)) * 0.05
	_origin = Vector2(w * 0.5, base_y + (_hop + bob) * _u)

	var breath := sin(_t * (2.1 - sad * 0.6))
	_sx = 1.0 - breath * 0.010
	_sy = 1.0 + breath * 0.014
	_rot = 0.0
	if _shake > 0.0:
		_rot = sin(_t * 55.0) * 0.10 * (_shake / 0.7)

	# Aura de la etapa legendaria
	if stage == MAX_STAGE:
		for i: int in 3:
			draw_circle(Vector2(_origin.x, _origin.y - 1.4 * _u),
				(1.7 + i * 0.38) * _u, Color(1.0, 0.84, 0.31, 0.035))

	# Sombra en el suelo (no salta con el dragón)
	var shadow_scale := clampf(1.0 - absf(_hop) * 0.12, 0.7, 1.0)
	_ellipse_screen(Vector2(_origin.x, base_y + 2.12 * _u),
		1.55 * _u * shadow_scale, 0.26 * _u * shadow_scale,
		Color(0.0, 0.0, 0.0, 0.28))

	var sad_t := float(sadness) / float(MAX_SADNESS)
	var body := _mix(_mix(Color("57C46C"), Color("8A9DA6"), sad_t * 0.55),
		Color("C9A227"), 0.10 if stage == MAX_STAGE else 0.0)
	var body_dark := _mix(Color("2F7C45"), Color("5E6D75"), sad_t * 0.45)
	var body_light := _mix(Color("74D486"), Color("A7B4BA"), sad_t * 0.5)
	var belly := _mix(Color("F4E7A6"), Color("BFC0B4"), sad_t * 0.45)
	var outline := _mix(Color("24522F"), Color("3C4A52"), sad_t * 0.5)
	var cream := Color("FFE082") if stage == MAX_STAGE else Color("F7F1D3")
	var membrane := _mix(Color("3E9E58"), Color("74858C"), sad_t * 0.5)
	var wing_bone := _mix(Color("2F7C45"), Color("5E6D75"), sad_t * 0.45)
	var dark := Color("22333A")

	# ---------------------------------------------------------- cola
	var sway := sin(_t * (1.7 - sad_t * 0.4)) * 0.16
	var tail := [
		Vector2(0.82, 0.82), Vector2(1.55, 0.98),
		Vector2(2.12, 0.55 + sway), Vector2(2.38, -0.05 + sway * 1.3),
		Vector2(2.12, -0.62 + sway * 1.5),
	]
	_polyline(tail, outline, 0.46, false)
	_polyline(tail, body, 0.30, false)

	var tip: Vector2 = tail[tail.size() - 1]
	var prev: Vector2 = tail[tail.size() - 2]
	var ang := (tip - prev).angle()
	var spade := [
		tip + Vector2(cos(ang), sin(ang)) * 0.34,
		tip + Vector2(cos(ang - 2.35), sin(ang - 2.35)) * 0.46,
		tip + Vector2(cos(ang + 2.35), sin(ang + 2.35)) * 0.46,
	]
	_poly(spade, cream if stage == MAX_STAGE else body_dark, outline, 0.05)

	if stage >= 2:
		for spike: Vector2 in [Vector2(1.30, 0.70), Vector2(1.82, 0.48), Vector2(2.10, -0.02)]:
			_poly([
				Vector2(spike.x - 0.15, spike.y),
				Vector2(spike.x, spike.y - 0.32),
				Vector2(spike.x + 0.15, spike.y),
			], cream if stage == MAX_STAGE else body_dark, outline, 0.04)

	# ---------------------------------------------------------- alas
	var wscale := float([0.34, 0.60, 0.80, 0.98, 1.10][stage])
	var flap := sin(_t * (2.3 - sad_t * 0.8)) * 0.07 + sad_t * 0.16
	var wing_shape := [
		Vector2(-0.15, -0.10), Vector2(-1.85, -1.65), Vector2(-1.70, -0.45),
		Vector2(-2.35, 0.55), Vector2(-1.28, 0.25), Vector2(-1.72, 1.12),
		Vector2(-0.52, 0.55),
	]
	for side: float in [-1.0, 1.0]:
		var attach := Vector2(side * 0.62, -0.62)
		var a := flap * side
		var pts: Array = []
		for base: Vector2 in wing_shape:
			var q := Vector2(side * base.x * wscale, base.y * wscale)
			pts.append(_rotate2(attach + q, attach, a))
		_poly(pts, membrane, wing_bone, 0.06)
		for bone: Vector2 in [Vector2(-1.85, -1.65), Vector2(-1.70, -0.45),
				Vector2(-2.35, 0.55), Vector2(-1.72, 1.12)]:
			var q := Vector2(side * bone.x * wscale, bone.y * wscale)
			var bp := _rotate2(attach + q, attach, a)
			_line(attach.x, attach.y, bp.x, bp.y, wing_bone, 0.055)

	# ---------------------------------------------------------- patas
	for x: float in [-0.62, 0.62]:
		_ellipse(x, 1.52, 0.44, 0.30, body, outline, 0.055)
		for dx: float in [-0.20, 0.0, 0.20]:
			_poly([
				Vector2(x + dx - 0.06, 1.66),
				Vector2(x + dx, 1.80),
				Vector2(x + dx + 0.06, 1.66),
			], cream, outline, 0.025)

	# ---------------------------------------------------------- cuerpo
	_ellipse(0, 0.32, 1.34, 1.24, body, outline, 0.07)
	_ellipse(0, 0.55, 0.86, 0.80, belly, Color(0.14, 0.32, 0.18, 0.35), 0.035)
	for i: int in 3:
		var yy := 0.32 + i * 0.26
		_arc(0, yy, 0.55, PI * 0.18, PI * 0.82,
			Color(0.47, 0.41, 0.22, 0.45), 0.04)

	# ---------------------------------------------------------- cáscara (bebé)
	if stage == 0:
		var shell := [
			Vector2(-1.22, 1.95), Vector2(-1.28, 1.16), Vector2(-0.92, 1.32),
			Vector2(-0.64, 1.06), Vector2(-0.32, 1.26), Vector2(0.0, 1.00),
			Vector2(0.32, 1.24), Vector2(0.62, 1.04), Vector2(0.92, 1.30),
			Vector2(1.24, 1.14), Vector2(1.22, 1.95),
		]
		_poly(shell, Color("FBF3D8"), Color("B9A978"), 0.055)
		for spot: Vector3 in [Vector3(-0.72, 1.52, 0.09), Vector3(-0.22, 1.66, 0.07),
				Vector3(0.42, 1.50, 0.08), Vector3(0.82, 1.68, 0.06)]:
			draw_circle(_p(spot.x, spot.y), spot.z * _u,
				Color(0.73, 0.66, 0.47, 0.55))

	# ---------------------------------------------------------- brazos
	for side: float in [-1.0, 1.0]:
		_ellipse(side * 1.14, 0.22, 0.30, 0.42, body, outline, 0.055)
		_poly([
			Vector2(side * 1.14 - 0.12, 0.56),
			Vector2(side * 1.14 - 0.06, 0.72),
			Vector2(side * 1.14, 0.56),
		], cream, outline, 0.02)
		_poly([
			Vector2(side * 1.14, 0.56),
			Vector2(side * 1.14 + 0.08, 0.72),
			Vector2(side * 1.14 + 0.14, 0.56),
		], cream, outline, 0.02)

	# ---------------------------------------------------------- cuello
	_ellipse(0, -1.12, 0.52, 0.46, body, outline, 0.065)

	# ---------------------------------------------------------- cabeza
	var hy := _droop * 0.26
	for side: float in [-1.0, 1.0]:
		_poly([
			Vector2(side * 0.88, -2.02 + hy),
			Vector2(side * 1.40, -2.42 + hy),
			Vector2(side * 0.98, -1.62 + hy),
		], body, outline, 0.05)

	var horn_len := 0.34 + float(stage) * 0.055
	for side: float in [-1.0, 1.0]:
		_quad_curve(
			Vector2(side * 0.41, -2.52 + hy),
			Vector2(side * 0.55, -2.85 - horn_len * 0.3 + hy),
			Vector2(side * (0.55 + horn_len * 0.55), -2.85 - horn_len * 0.55 + hy),
			cream, 0.18)
		_quad_curve(
			Vector2(side * 0.44, -2.58 + hy),
			Vector2(side * 0.56, -2.85 - horn_len * 0.3 + hy),
			Vector2(side * (0.52 + horn_len * 0.5), -2.82 - horn_len * 0.55 + hy),
			Color(0.47, 0.39, 0.16, 0.45), 0.05)

	_ellipse(0, -1.90 + hy, 1.02, 0.92, body, outline, 0.07)
	_ellipse(-0.35, -2.18 + hy, 0.52, 0.34, Color(1, 1, 1, 0.10), Color.TRANSPARENT, 0.0)
	_ellipse(0, -1.52 + hy, 0.62, 0.42, body_light, Color(0.14, 0.32, 0.18, 0.5), 0.045)

	for x: float in [-0.19, 0.19]:
		draw_circle(_p(x, -1.62 + hy), 0.045 * _u, Color(0.12, 0.20, 0.14, 0.55))

	if sadness <= 1:
		for x: float in [-0.74, 0.74]:
			draw_circle(_p(x, -1.76 + hy), 0.13 * _u, Color(0.95, 0.56, 0.63, 0.55))

	# ojos
	var eyes := [Vector2(-0.40, -2.05), Vector2(0.40, -2.05)]
	for idx in 2:
		var ex: float = eyes[idx].x
		var ey: float = eyes[idx].y + hy
		if sadness >= 3:
			_arc(ex, ey + 0.02, 0.24, PI * 0.16, PI * 0.84, dark, 0.065)
		else:
			_ellipse(ex, ey, 0.255, 0.275, Color.WHITE, dark, 0.04)
			var look := 0.07 if sadness >= 2 else 0.02
			var px := ex + (0.02 if idx == 0 else -0.02)
			draw_circle(_p(px, ey + look), 0.115 * _u, dark)
			draw_circle(_p(px - 0.045, ey + look - 0.055), 0.045 * _u, Color.WHITE)
			if sadness >= 2:
				_ellipse(ex, ey - 0.30, 0.30, 0.22, body, Color.TRANSPARENT, 0.0)
				_line(ex - 0.26, ey - 0.16, ex + 0.26, ey - 0.16, outline, 0.035)

	# cejas
	var brow_y := -2.42 + hy
	var brow_drop := float(sadness) * 0.05
	for side: float in [-1.0, 1.0]:
		if sadness == 0:
			_arc(side * 0.40, brow_y, 0.26, PI * 1.15, PI * 1.85, dark, 0.065)
		else:
			_line(side * 0.62, brow_y + brow_drop,
				side * 0.20, brow_y - brow_drop, dark, 0.065)

	# boca
	if sadness == 0:
		_arc(0, -1.50 + hy, 0.27, PI * 0.18, PI * 0.82, dark, 0.055)
		for x: float in [-0.24, 0.24]:
			_poly([
				Vector2(x, -1.43 + hy),
				Vector2(x + 0.07, -1.33 + hy),
				Vector2(x + 0.14, -1.43 + hy),
			], Color.WHITE, Color.TRANSPARENT, 0.0)
	elif sadness == 1:
		_line(-0.18, -1.42 + hy, 0.18, -1.42 + hy, dark, 0.055)
	else:
		var r := 0.32 if sadness >= 3 else 0.26
		_arc(0, -1.24 + hy, r, PI * 1.17, PI * 1.83, dark, 0.055)

	# lágrimas
	if sadness >= 2:
		var fall := fmod(_t * 0.55, 1.0)
		for ex: float in [-0.40, 0.40]:
			var yy := -1.72 + hy + fall * 0.85
			draw_circle(_p(ex, yy), 0.075 * _u,
				Color(0.56, 0.89, 1.0, 0.85 * (1.0 - fall)))
			draw_circle(_p(ex, -1.81 + hy), 0.065 * _u,
				Color(0.56, 0.89, 1.0, 0.95))

	if sadness == 0:
		draw_circle(_p(0.14, -1.48 + hy), 0.05 * _u, Color(1, 1, 1, 0.75))

	# ---------------------------------------------------------- destellos legendarios
	if stage == MAX_STAGE:
		for i: int in 8:
			var a := _t * 0.5 + float(i) * TAU / 8.0
			var rx := 2.6 * _u + sin(_t * 1.3 + float(i)) * 0.18 * _u
			var ry := 1.9 * _u
			var pos := Vector2(_origin.x + cos(a) * rx,
				_origin.y - 1.5 * _u + sin(a) * ry)
			var tw := 0.45 + 0.35 * sin(_t * 2.4 + float(i) * 1.7)
			_draw_star(pos, (0.11 + 0.03 * sin(_t * 2.0 + float(i))) * _u,
				_t * 0.7 + float(i), Color(1.0, 0.88, 0.51, maxf(0.1, tw)))

	# ---------------------------------------------------------- partículas
	for p: Dictionary in _particles:
		var alpha := clampf(float(p["life"]) * 1.6, 0.0, 1.0)
		var pos: Vector2 = p["pos"]
		if p["kind"] == "heart":
			_draw_heart(pos, float(p["size"]), float(p["rot"]),
				Color(1.0, 0.43, 0.60, alpha))
		else:
			_draw_star(pos, float(p["size"]) * 0.8, float(p["rot"]),
				Color(1.0, 0.84, 0.31, alpha))


# ---------------------------------------------------------------- Primitivas

func _p(x: float, y: float) -> Vector2:
	return _tx(Vector2(x, y) * _u)


func _tx(v: Vector2) -> Vector2:
	var q := Vector2(v.x * _sx, v.y * _sy)
	return _origin + q.rotated(_rot)


func _line(x1: float, y1: float, x2: float, y2: float, color: Color, width: float) -> void:
	draw_line(_p(x1, y1), _p(x2, y2), color, width * _u, true)


func _polyline(points: Array, color: Color, width: float, closed := false) -> void:
	var pts := PackedVector2Array()
	for pt: Vector2 in points:
		pts.append(_p(pt.x, pt.y))
	if closed and pts.size() > 0:
		pts.append(pts[0])
	draw_polyline(pts, color, width * _u, true)


func _poly(points: Array, color: Color, stroke := Color.TRANSPARENT, stroke_w := 0.055) -> void:
	var pts := PackedVector2Array()
	for pt: Vector2 in points:
		pts.append(_p(pt.x, pt.y))
	_tri_fill(pts, color)
	if stroke.a > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, stroke, stroke_w * _u, true)


func _ellipse(cx: float, cy: float, rx: float, ry: float,
		color: Color, stroke := Color.TRANSPARENT, stroke_w := 0.055) -> void:
	var pts := PackedVector2Array()
	for i: int in 49:
		var a := TAU * float(i) / 48.0
		pts.append(_tx(Vector2(cx * _u + cos(a) * rx * _u,
			cy * _u + sin(a) * ry * _u)))
	draw_colored_polygon(pts, color)
	if stroke.a > 0.0:
		var closed := pts.duplicate()
		closed.append(pts[0])
		draw_polyline(closed, stroke, stroke_w * _u, true)


func _ellipse_screen(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i: int in 49:
		var a := TAU * float(i) / 48.0
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _tri_fill(pts: PackedVector2Array, color: Color) -> void:
	# Rellena también formas cóncavas (alas, corazones y estrellas).
	var indices := Geometry2D.triangulate_polygon(pts)
	if indices.size() < 3:
		draw_colored_polygon(pts, color)
		return
	var i := 0
	while i + 2 < indices.size():
		draw_colored_polygon(PackedVector2Array([
			pts[indices[i]], pts[indices[i + 1]], pts[indices[i + 2]]]), color)
		i += 3


func _arc(cx: float, cy: float, r: float, a0: float, a1: float,
		color: Color, width: float, segments := 28) -> void:
	var pts := PackedVector2Array()
	for i in segments + 1:
		var a := lerpf(a0, a1, float(i) / float(segments))
		pts.append(_p(cx + cos(a) * r, cy + sin(a) * r))
	draw_polyline(pts, color, width * _u, true)


func _quad_curve(p0: Vector2, p1: Vector2, p2: Vector2, color: Color, width: float) -> void:
	var pts := PackedVector2Array()
	for i: int in 15:
		var t := float(i) / 14.0
		var a := p0.lerp(p1, t)
		var b := p1.lerp(p2, t)
		pts.append(_p(a.lerp(b, t).x, a.lerp(b, t).y))
	draw_polyline(pts, color, width * _u, true)


func _rotate2(point: Vector2, pivot: Vector2, angle: float) -> Vector2:
	return pivot + (point - pivot).rotated(angle)


func _mix(a: Color, b: Color, t: float) -> Color:
	return a.lerp(b, clampf(t, 0.0, 1.0))


func _heart_points(center: Vector2, s: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 29:
		var a := TAU * float(i) / 28.0
		var x := 16.0 * pow(sin(a), 3.0)
		var y := -(13.0 * cos(a) - 5.0 * cos(2.0 * a)
			- 2.0 * cos(3.0 * a) - cos(4.0 * a))
		pts.append(center + Vector2(x, y).rotated(rot) * (s / 16.0))
	return pts


func _star_points(center: Vector2, s: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i: int in 10:
		var r := s if i % 2 == 0 else s * 0.45
		var a := -PI / 2.0 + float(i) * PI / 5.0 + rot
		pts.append(center + Vector2(cos(a), sin(a)) * r)
	return pts


func _draw_heart(center: Vector2, s: float, rot: float, color: Color) -> void:
	_tri_fill(_heart_points(center, s, rot), color)


func _draw_star(center: Vector2, s: float, rot: float, color: Color) -> void:
	_tri_fill(_star_points(center, s, rot), color)
