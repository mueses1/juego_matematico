class_name Ladder
extends Control
## Escalera de 3 peldaños. La ficha sube o baja según las respuestas.

const NAMES := ["Básico", "Medio", "Superior"]
const COLORS := [Color("4CAF50"), Color("FFB300"), Color("E53935")]

var level := 0:
	set(value):
		level = value
		queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var w := size.x
	var h := size.y
	var rail := Color("D7B98E")
	draw_line(Vector2(w * 0.2, 20), Vector2(w * 0.2, h - 20), rail, 10.0)
	draw_line(Vector2(w * 0.8, 20), Vector2(w * 0.8, h - 20), rail, 10.0)
	for i in 3:
		var y := h - h * (i + 0.5) / 3.0
		draw_line(Vector2(w * 0.2, y), Vector2(w * 0.8, y), COLORS[i], 14.0)
		draw_string(font, Vector2(0, y - 26), NAMES[i],
			HORIZONTAL_ALIGNMENT_CENTER, w, 26, Color.WHITE)
	var ty := h - h * (level + 0.5) / 3.0
	draw_circle(Vector2(w * 0.5, ty), 24.0, Color.WHITE)
	draw_circle(Vector2(w * 0.5, ty), 17.0, COLORS[level])
