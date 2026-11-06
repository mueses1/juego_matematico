class_name Wheel
extends Control
## Ruleta de inicio: gira y se detiene en Básico, Medio o Superior.

signal finished(index: int)

const NAMES := ["Básico", "Medio", "Superior"]
const COLORS := [Color("4CAF50"), Color("FFB300"), Color("E53935")]

var spinning := false
var wheel_angle := 0.0:
	set(value):
		wheel_angle = value
		queue_redraw()


func spin() -> void:
	if spinning:
		return
	spinning = true
	var idx := randi() % 3
	var seg := TAU / 3.0
	wheel_angle = fposmod(wheel_angle, TAU)
	# Deja el centro del sector elegido justo bajo el puntero (arriba)
	var target := wheel_angle + TAU * 5.0 + fposmod(-(idx + 0.5) * seg - wheel_angle, TAU)
	var tw := create_tween()
	tw.tween_property(self, "wheel_angle", target, 4.0) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tw.finished
	spinning = false
	finished.emit(idx)


func _draw() -> void:
	var c := size / 2.0
	var r: float = min(size.x, size.y) / 2.0 - 24.0
	var seg := TAU / 3.0
	var font := ThemeDB.fallback_font
	for i in 3:
		var a0 := -PI / 2.0 + i * seg + wheel_angle
		var pts := PackedVector2Array([c])
		for s in range(0, 33):
			var a := a0 + seg * s / 32.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
		draw_colored_polygon(pts, COLORS[i])
		var mid := a0 + seg / 2.0
		var tp := c + Vector2(cos(mid), sin(mid)) * r * 0.62
		draw_string(font, tp + Vector2(-60, 9), NAMES[i],
			HORIZONTAL_ALIGNMENT_CENTER, 120, 26, Color.WHITE)
	draw_arc(c, r, 0.0, TAU, 96, Color.WHITE, 6.0)
	draw_circle(c, 18.0, Color.WHITE)
	# Puntero superior
	draw_colored_polygon(PackedVector2Array([
		c + Vector2(-16, -r - 20),
		c + Vector2(16, -r - 20),
		c + Vector2(0, -r + 22)
	]), Color("FFD54F"))
