extends Control
## Escaleras Matemáticas (9°) — edición Dragón
## 1) La ruleta decide el nivel inicial de las preguntas.
## 2) Acierto: el dragón se alegra, crece y sube la dificultad.
## 3) Error: el dragón se entristece (máximo 3 niveles de tristeza).
## 4) Se gana cuando el dragón llega a la etapa Legendario.

const LEVEL_NAMES := ["Básico", "Medio", "Superior"]
const LEVEL_COLORS := [Color("4CAF50"), Color("FFB300"), Color("E53935")]

var level := 0
var pending_level := -1
var correct_total := 0
var wrong_total := 0
var won := false
var answered := false
var current: Dictionary = {}
var correct_text := ""

var pools: Array = []
var pool_pos: Array = [0, 0, 0]

var dragon: Dragon
var wheel: Wheel
var status_label: Label
var roulette_box: VBoxContainer
var question_box: VBoxContainer
var spin_btn: Button
var roulette_label: Label
var level_label: Label
var question_label: Label
var feedback_label: Label
var next_btn: Button
var dragon_name_label: Label
var mood_label: Label
var stage_label: Label
var evo_bar: ProgressBar
var answer_buttons: Array[Button] = []


func _ready() -> void:
	randomize()
	for l in 3:
		var p: Array = Questions.BANK[l].duplicate()
		p.shuffle()
		pools.append(p)
	_build_ui()
	_show_roulette()


# ---------------------------------------------------------------- UI

func _make_label(font_size: int, color := Color.WHITE) -> Label:
	var lb := Label.new()
	lb.add_theme_font_size_override("font_size", font_size)
	lb.add_theme_color_override("font_color", color)
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return lb


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color("1B2A49")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	add_child(margin)

	var root := HBoxContainer.new()
	root.add_theme_constant_override("separation", 24)
	margin.add_child(root)

	# ----- Panel del dragón -----
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(360, 0)
	root.add_child(left)

	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("12203C")
	panel_style.border_color = Color("2C4A78")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(18)
	panel.add_theme_stylebox_override("panel", panel_style)
	left.add_child(panel)

	var panel_margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		panel_margin.add_theme_constant_override("margin_" + side, 14)
	panel.add_child(panel_margin)

	var panel_box := VBoxContainer.new()
	panel_box.add_theme_constant_override("separation", 4)
	panel_margin.add_child(panel_box)

	dragon_name_label = _make_label(26, Color("FFD54F"))
	panel_box.add_child(dragon_name_label)

	dragon = Dragon.new()
	dragon.custom_minimum_size = Vector2(320, 320)
	dragon.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel_box.add_child(dragon)

	mood_label = _make_label(19)
	panel_box.add_child(mood_label)

	stage_label = _make_label(17, Color("9DB3D4"))
	panel_box.add_child(stage_label)

	evo_bar = ProgressBar.new()
	evo_bar.max_value = Dragon.MAX_STAGE
	evo_bar.show_percentage = false
	evo_bar.custom_minimum_size = Vector2(0, 14)
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("0C1729")
	bar_bg.set_corner_radius_all(7)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("FFD54F")
	bar_fill.set_corner_radius_all(7)
	evo_bar.add_theme_stylebox_override("background", bar_bg)
	evo_bar.add_theme_stylebox_override("fill", bar_fill)
	panel_box.add_child(evo_bar)

	# ----- Columna de juego -----
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 12)
	root.add_child(right)

	status_label = _make_label(22, Color("FFD54F"))
	right.add_child(status_label)

	# ----- Vista de ruleta -----
	roulette_box = VBoxContainer.new()
	roulette_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roulette_box.alignment = BoxContainer.ALIGNMENT_CENTER
	roulette_box.add_theme_constant_override("separation", 14)
	right.add_child(roulette_box)

	roulette_label = _make_label(28)
	roulette_box.add_child(roulette_label)

	wheel = Wheel.new()
	wheel.custom_minimum_size = Vector2(400, 400)
	wheel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	wheel.finished.connect(_on_wheel_finished)
	roulette_box.add_child(wheel)

	spin_btn = Button.new()
	spin_btn.text = "¡Girar la ruleta!"
	spin_btn.add_theme_font_size_override("font_size", 26)
	spin_btn.custom_minimum_size = Vector2(280, 60)
	spin_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	spin_btn.pressed.connect(_on_spin_pressed)
	roulette_box.add_child(spin_btn)

	# ----- Vista de pregunta -----
	question_box = VBoxContainer.new()
	question_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	question_box.alignment = BoxContainer.ALIGNMENT_CENTER
	question_box.add_theme_constant_override("separation", 12)
	right.add_child(question_box)

	level_label = _make_label(24)
	question_box.add_child(level_label)

	question_label = _make_label(30)
	question_box.add_child(question_label)

	for i in 4:
		var b := Button.new()
		b.add_theme_font_size_override("font_size", 24)
		b.custom_minimum_size = Vector2(0, 58)
		b.pressed.connect(_on_answer_pressed.bind(i))
		question_box.add_child(b)
		answer_buttons.append(b)

	feedback_label = _make_label(22)
	question_box.add_child(feedback_label)

	next_btn = Button.new()
	next_btn.add_theme_font_size_override("font_size", 24)
	next_btn.custom_minimum_size = Vector2(260, 56)
	next_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	next_btn.pressed.connect(_on_next_pressed)
	question_box.add_child(next_btn)


func _update_status() -> void:
	status_label.text = "Nivel: %s   |   Aciertos: %d   |   Errores: %d" % [
		LEVEL_NAMES[level], correct_total, wrong_total]
	dragon_name_label.text = "Dragón %s" % Dragon.STAGE_NAMES[dragon.stage]
	mood_label.text = "Ánimo: %s" % Dragon.MOOD_NAMES[dragon.sadness]
	mood_label.add_theme_color_override("font_color", Dragon.MOOD_COLORS[dragon.sadness])
	stage_label.text = "Etapa %d de %d" % [dragon.stage, Dragon.MAX_STAGE]
	evo_bar.value = dragon.stage


# ---------------------------------------------------------------- Ruleta

func _show_roulette() -> void:
	won = false
	answered = false
	pending_level = -1
	roulette_box.visible = true
	question_box.visible = false
	spin_btn.disabled = false
	roulette_label.text = "Gira la ruleta para saber con qué nivel empieza el reto"
	_update_status()


func _on_spin_pressed() -> void:
	spin_btn.disabled = true
	roulette_label.text = "Girando..."
	wheel.spin()


func _on_wheel_finished(idx: int) -> void:
	level = idx
	roulette_label.text = "¡Empiezas en el nivel %s!" % LEVEL_NAMES[level]
	_update_status()
	await get_tree().create_timer(1.4).timeout
	_show_question()


# ---------------------------------------------------------------- Preguntas

func _next_question(l: int) -> Dictionary:
	var pool: Array = pools[l]
	if pool_pos[l] >= pool.size():
		pool.shuffle()
		pool_pos[l] = 0
	var q: Dictionary = pool[pool_pos[l]]
	pool_pos[l] += 1
	return q


func _show_question() -> void:
	roulette_box.visible = false
	question_box.visible = true
	answered = false
	if pending_level >= 0:
		level = pending_level
		pending_level = -1
	current = _next_question(level)
	correct_text = current["o"][0]
	var opts: Array = current["o"].duplicate()
	opts.shuffle()

	level_label.text = "Nivel %s" % LEVEL_NAMES[level]
	level_label.add_theme_color_override("font_color", LEVEL_COLORS[level])
	question_label.text = current["q"]
	for i in 4:
		answer_buttons[i].text = opts[i]
		answer_buttons[i].disabled = false
		answer_buttons[i].modulate = Color.WHITE
	feedback_label.text = ""
	feedback_label.add_theme_color_override("font_color", Color.WHITE)
	next_btn.visible = false
	_update_status()


func _on_answer_pressed(i: int) -> void:
	if answered:
		return
	answered = true
	var ok := answer_buttons[i].text == correct_text
	for b in answer_buttons:
		b.disabled = true
		if b.text == correct_text:
			b.modulate = Color("66BB6A")
	if not ok:
		answer_buttons[i].modulate = Color("EF5350")

	var msg := ""
	if ok:
		correct_total += 1
		dragon.celebrate()
		if dragon.stage < Dragon.MAX_STAGE:
			dragon.grow()
		if level < 2:
			pending_level = level + 1
		if dragon.stage >= Dragon.MAX_STAGE:
			won = true
			msg = "¡Correcto! Tu dragón llegó a la etapa Legendario. ¡Ganaste!"
		else:
			msg = "¡Correcto! Tu dragón está feliz y creció: ahora es %s." \
				% Dragon.STAGE_NAMES[dragon.stage]
	else:
		wrong_total += 1
		dragon.make_sad()
		msg = "Incorrecto. La respuesta era: %s. El dragón se pone %s; anímate a la siguiente." \
			% [correct_text, Dragon.MOOD_NAMES[dragon.sadness]]

	feedback_label.text = msg + "\n" + current["e"]
	feedback_label.add_theme_color_override("font_color",
		Color("8BE28B") if ok else Color("FFAB91"))

	next_btn.text = "¡Jugar de nuevo!" if won else "Siguiente pregunta"
	next_btn.visible = true
	_update_status()


func _on_next_pressed() -> void:
	if won:
		_reset_game()
	else:
		_show_question()


func _reset_game() -> void:
	level = 0
	correct_total = 0
	wrong_total = 0
	dragon.reset()
	_show_roulette()
