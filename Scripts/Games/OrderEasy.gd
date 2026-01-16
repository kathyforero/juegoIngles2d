extends Node2D

# Signals
signal set_timer()
signal update_title(new_title)
signal update_difficulty(new_difficulty)
signal update_level(new_level)
signal uptate_imagen_game(new_image)
signal set_visible_word(new_word)

var ejecutablePath = Global.rutaArchivos
var pantallaVictoria = preload("res://Escenas/PantallaVictoria.tscn")
var pantallaTimeAttackFin = preload("res://Escenas/PantallaTimeAttackFin.tscn")

var pantallaAcaboTiempo = preload("res://Escenas/NivelFinalizado.tscn")
var difuminado = preload("res://Piezas/ColorRectDifuminado.tscn")

@onready var hints_panel = $HintsPanel
@onready var hints_label = $HintsPanel/Label
var pistas_restantes := 3  # Easy: 3 hints

var instance
var instanceAcaboTiempo
var instantiatedAcaboTiempo = false
var instanceDifuminado
var instantiatedDifuminado = false

# esp → eng
var palabras: Dictionary = {}
# esp → image id (ej: "order_easy_01")
var palabras_imagen: Dictionary = {}

@export var palabra = "BIRD"
@export var palabraES = "Ave"
var instantiated = false
var gano = false
var letters
var rondas = 4
var rondaActual = 1
var tiempoCronometro = 120 
var velocidad = 20
var perfect = 100
var valorNivel = 100
var palabraAnterior

# --- TIME ATTACK (Contrarreloj) ---
var _is_time_attack: bool = false
var _ta_finished: bool = false
var _ta_transitioning: bool = false

var _classic_transitioning: bool = false

var _ta_live_score_last: int = 0

var _is_practice: bool = false

func _ta_update_live_score(force_delta_zero: bool = false) -> void:
	if not _is_time_attack:
		return

	var new_score := Score.calc_time_attack_score(
		Score.levels_completed,
		Score.time_attack_seconds,
		int(Score.perfectBonus)
	)

	var delta := 0 if force_delta_zero else (new_score - _ta_live_score_last)
	_ta_live_score_last = new_score

	if $Box_inside_game and $Box_inside_game.has_method("set_time_attack_score"):
		$Box_inside_game.set_time_attack_score(new_score, delta)

func _ready():
	_is_time_attack = (Score.current_mode == Score.Mode.TIME_ATTACK)
	_is_practice = (Score.current_mode == Score.Mode.PRACTICE)
	_ta_finished = false
	_ta_transitioning = false


	# Precision starts full each run
	Score.perfectBonus = 100
	Score.fastBonus = 0

	# Time Attack: tiempo configurado + contador infinito
	if _is_time_attack:
		tiempoCronometro = int(Score.time_attack_seconds)
		Score.levels_completed = 0

	_cargar_palabras_desde_banco_easy()

	# 1) Pasar el tiempo correcto al HUD
	$Box_inside_game.time_seconds = tiempoCronometro

	# 2) Ahora sí inicializar el HUD
	if not _is_practice:
		emit_signal("set_timer")
	emit_signal("update_title", "Order it")
	setDifficultTitle()
	if _is_time_attack:
		emit_signal("update_level", str(Score.levels_completed))
	else:
		emit_signal("update_level", "1/" + str(rondas))

	instance = pantallaVictoria.instantiate()
	instantiated = true
	instanceAcaboTiempo = pantallaAcaboTiempo.instantiate()
	instantiatedAcaboTiempo = true
	instanceDifuminado = difuminado.instantiate()
	instantiatedDifuminado = true

	setLetters()
	if _is_time_attack:
		_ta_update_live_score(true)


func _process(_delta):
	if not instantiated:
		return

	# Lock anti doble transición (como Medium)
	if _classic_transitioning:
		return

	var all_correct = (
		$Letras/Letter.correct
		and $Letras/Letter2.correct
		and $Letras/Letter3.correct
		and $Letras/Letter4.correct
	)

	# --- TIME ATTACK: loop infinito hasta que se acabe el tiempo ---
	if _is_time_attack:
		if _ta_finished or _ta_transitioning:
			return
		if all_correct:
			_ta_transitioning = true
			await _await_mouse_release()
			await _await_letters_settle()
			await nuevaRonda()
			_ta_transitioning = false
		return

	# --- PRACTICE: loop infinito, sin victory, sin records ---
	if _is_practice:
		if all_correct:
			_classic_transitioning = true
			await _await_mouse_release()
			await _await_letters_settle()
			await nuevaRonda()
			_classic_transitioning = false
		return

	# --- MODO CLÁSICO ---
	if all_correct and rondaActual == rondas and !gano:
		_classic_transitioning = true
		gano = true
		await _await_mouse_release()
		await _await_letters_settle()
		await victory()
		_classic_transitioning = false
		return

	if all_correct and rondaActual < rondas:
		_classic_transitioning = true
		await _await_mouse_release()
		await _await_letters_settle()
		await nuevaRonda()
		_classic_transitioning = false


func _await_letters_settle() -> void:
	var letras := $Letras.get_children()
	while true:
		var any_playing := false
		for l in letras:
			var ap := l.get_node_or_null("AnimationPlayer") as AnimationPlayer
			if ap != null and ap.is_playing():
				any_playing = true
				break
		if not any_playing:
			break
		await get_tree().process_frame


func _await_mouse_release() -> void:
	while Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		await get_tree().process_frame


func _cargar_palabras_desde_banco_easy():
	palabras.clear()
	palabras_imagen.clear()

	if typeof(BancoOrderIt) == TYPE_NIL:
		push_error("Autoload 'BancoOrderIt' not found. Check Project Settings → AutoLoad.")
		return
	
	for ejercicio in BancoOrderIt.easy:
		if ejercicio.has("esp") and ejercicio.has("eng"):
			var esp := str(ejercicio["esp"])
			var eng := str(ejercicio["eng"])
			palabras[esp] = eng
			if ejercicio.has("image"):
				palabras_imagen[esp] = str(ejercicio["image"])

func setDifficultTitle():
	match Score.actualDifficult:
		Score.difficult["easy"]:
			emit_signal("update_difficulty", "Easy")
		Score.difficult["medium"]:
			emit_signal("update_difficulty", "Medium")
		Score.difficult["hard"]:
			emit_signal("update_difficulty", "Difficult")

func setLetters():
	# Recargar banco si se acabó (Time Attack puede ser infinito)
	if palabras.size() == 0:
		_cargar_palabras_desde_banco_easy()
	# Elegir palabra al azar
	palabraES = palabras.keys().pick_random()
	emit_signal("set_visible_word", palabraES)

	# Imagen desde el banco (se cargará en Box_order_hud)
	if palabras_imagen.has(palabraES):
		emit_signal("uptate_imagen_game", palabras_imagen[palabraES])

	palabra = palabras[palabraES]
	letters = palabra.split()
	var tempLetters: Array[String] = []

	# Barajar letras pero que la primera no coincida con la original
	while true:
		tempLetters.clear()
		for i in letters.size():
			tempLetters.append(letters[i])
		tempLetters.shuffle()
		if tempLetters[0] != letters[0]:
			break

	# Asignar letras desordenadas
	$Letras/Letter.setLetter(tempLetters[0])
	$Letras/Letter2.setLetter(tempLetters[1])
	$Letras/Letter3.setLetter(tempLetters[2])
	$Letras/Letter4.setLetter(tempLetters[3])

	# Asignar orden correcto
	$Ordenada/Letterbox5.setLetter(letters[0])
	$Ordenada/Letterbox6.setLetter(letters[1])
	$Ordenada/Letterbox7.setLetter(letters[2])
	$Ordenada/Letterbox8.setLetter(letters[3])

func victory():
	if _is_practice: return

	$Box_inside_game.timer.stop()
	actualizar_velocidad()
	_actualizar_puntajes(ejecutablePath + "/Scores/puntajesOrder.dat")

	var totalActual = velocidad + Score.perfectBonus + valorNivel
	Score.newScore = valorNivel
	Score.fastBonus = velocidad
	# Score.perfectBonus ya viene modificado por Letter.gd
	Score.LatestGame = Score.Games.OrderIt
	var time_spent = max(0.0, float(tiempoCronometro) - float($Box_inside_game.time_seconds))
	var is_perfect := int(Score.perfectBonus) >= 100
	Score.register_minigame_victory("order", Score.actualDifficult, time_spent, is_perfect, false)

	actualizar_progreso(ejecutablePath + "/Progress/progressMinigames.dat")
	instance.position = Vector2(1000, 0)
	$AnimationPlayer.play("Gana")
	await $AnimationPlayer.animation_finished
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instance)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	$AudioStreamPlayer2D.play()
	while instance.position.x > 0:
		await get_tree().create_timer(0.000000001).timeout
		instance.position.x -= 50

func _actualizar_puntajes(path):
	var precisionActual = Score.perfectBonus
	var totalActual = velocidad + precisionActual + valorNivel
	var is_new_record := false
	var diff_key := "easy"  # este script es SOLO para Easy

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var puntajes = file.get_var()
		file.close()

		# Asegurar que existan las 3 dificultades con la estructura nueva
		for diff in ["easy", "medium", "hard"]:
			if not puntajes.has(diff):
				puntajes[diff] = {
					"velocidad": 0,
					"precision": 0,
					"niveles": 0,
					"best_score": 0,
					"name": ""
				}
			else:
				# Migrar archivos viejos sin best_score / name
				if not puntajes[diff].has("best_score"):
					var v = int(puntajes[diff].get("velocidad", 0))
					var p = int(puntajes[diff].get("precision", 0))
					var n = int(puntajes[diff].get("niveles", 0))
					puntajes[diff]["best_score"] = v + p + n
				if not puntajes[diff].has("name"):
					puntajes[diff]["name"] = ""

		var registro_actual = puntajes[diff_key]
		var best_prev := int(registro_actual.get("best_score", 0))

		if totalActual >= best_prev:
			is_new_record = true
			var nombre_guardado = registro_actual.get("name", "")
			puntajes[diff_key] = {
				"velocidad": velocidad,
				"precision": precisionActual,
				"niveles": valorNivel,
				"best_score": totalActual,
				"name": nombre_guardado   # se actualiza luego desde Puntaje.gd
			}

			var new_file = FileAccess.open(path, FileAccess.WRITE)
			new_file.store_var(puntajes)
			new_file = null
	else:
		# No existe archivo: lo creamos desde cero
		is_new_record = true
		var content = {
			"easy": {
				"velocidad": velocidad,
				"precision": precisionActual,
				"niveles": valorNivel,
				"best_score": totalActual,
				"name": ""
			},
			"medium": {
				"velocidad": 0, "precision": 0, "niveles": 0,
				"best_score": 0, "name": "---"
			},
			"hard": {
				"velocidad": 0, "precision": 0, "niveles": 0,
				"best_score": 0, "name": "---"
			}
		}

		var file = FileAccess.open(path, FileAccess.WRITE)
		file.store_var(content)
		file = null

	# Flags globales para la pantalla de puntajes
	Score.latest_total_score = totalActual
	Score.is_new_best = is_new_record

func _guardar_puntajes(content, path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_var(content)
	file = null

func actualizar_progreso(path):
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var progreso = file.get_var()
		file = null
		var esPrimeraVez = false
		match Score.actualDifficult:
			Score.difficult["easy"]:
				if progreso["order"]["medium"] and progreso["order"]["firstMedium"] == false:
					esPrimeraVez = false
				else:
					esPrimeraVez = true
					progreso["order"]["medium"] = true
					progreso["order"]["firstMedium"] = true
			Score.difficult["medium"]:
				if progreso["order"]["hard"] and progreso["order"]["firstHard"] == false:
					esPrimeraVez = false
				else:
					esPrimeraVez = true
					progreso["order"]["hard"] = true
					progreso["order"]["firstHard"] = true
		if esPrimeraVez:
			if DirAccess.remove_absolute(path) == OK:
				print("Archivo PROGRESO existente borrado.")
				var new_file = FileAccess.open(path, FileAccess.WRITE)
				new_file.store_var(progreso)
				new_file = null
			else:
				print("Error al intentar borrar el archivo PROGRESO.")

func lose():
	if _is_practice: return

	$Box_inside_game.timer.stop()
	get_tree().paused = true
	instanceAcaboTiempo.nombreEscenaDificultad = "Dificultad_OrderIt.tscn"
	instanceAcaboTiempo.position = Vector2(1000, 0)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instanceAcaboTiempo)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	while instanceAcaboTiempo.position.x > 0:
		await get_tree().create_timer(0.000000001).timeout
		instanceAcaboTiempo.position.x -= 50

func finish_time_attack() -> void:
	if not _is_time_attack:
		return
	if _ta_finished:
		return
	_ta_finished = true

	# Parar timer HUD para evitar dobles llamadas
	$Box_inside_game.timer.stop()
	var btn_inst := $Box_inside_game.get_node_or_null("btns_inside_box_game/btn_instructions")
	if btn_inst != null:
		btn_inst.disabled = true

	# Score: niveles + tiempo escogido (base) + precisión (bonus). Sin speed bonus.
	Score.LatestGame = Score.Games.OrderIt
	Score.fastBonus = 0

	var precision_bonus := int(Score.perfectBonus)
	if Score.levels_completed <= 0:
		precision_bonus = 0
		Score.perfectBonus = 0

	var total := Score.calc_time_attack_score(Score.levels_completed, Score.time_attack_seconds, precision_bonus)
	var base := total - precision_bonus

	if base < 0:
		base = 0

	Score.newScore = base
	Score.latest_total_score = total

	# Guardado por modo/dificultad (Time Attack)
	_actualizar_puntajes_time_attack(ejecutablePath + "/Scores/puntajesOrder.dat", total)

	instance = pantallaTimeAttackFin.instantiate()
	_lock_interaction_time_over_order()
	_show_time_over_overlay()


func _lock_interaction_time_over_order() -> void:
	# Letter.gd ya tiene locked/dragging, así que es el candado perfecto
	if has_node("Letras"):
		for l in $Letras.get_children():
			if l == null:
				continue
			if l.get("dragging") != null:
				l.dragging = false
			if l.get("locked") != null:
				l.locked = true

func _show_time_over_overlay() -> void:
	# Igual que _show_victory_overlay() pero SIN $AnimationPlayer.play("Gana")
	instance.position = Vector2(1000, 0)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instance)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	$AudioStreamPlayer2D.play()
	while instance.position.x > 0:
		await get_tree().create_timer(0.000000001).timeout
		instance.position.x -= 50


func _show_victory_overlay() -> void:
	instance.position = Vector2(1000, 0)
	$AnimationPlayer.play("Gana")
	await $AnimationPlayer.animation_finished
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instance)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	$AudioStreamPlayer2D.play()
	while instance.position.x > 0:
		await get_tree().create_timer(0.000000001).timeout
		instance.position.x -= 50

func _actualizar_puntajes_time_attack(path:String, totalActual:int) -> void:
	var is_new_record := false
	var diff_key := "easy"

	var puntajes: Dictionary = {}

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		puntajes = file.get_var()
		file.close()
	else:
		# Si no existe, creamos el formato base clásico para no romper nada
		puntajes = {
			"easy": {"velocidad": 0, "precision": 0, "niveles": 0, "best_score": 0, "name": "---"},
			"medium": {"velocidad": 0, "precision": 0, "niveles": 0, "best_score": 0, "name": "---"},
			"hard": {"velocidad": 0, "precision": 0, "niveles": 0, "best_score": 0, "name": "---"}
		}

	# Asegurar rama time_attack
	if not puntajes.has("time_attack"):
		puntajes["time_attack"] = {}

	for diff in ["easy", "medium", "hard"]:
		if not puntajes["time_attack"].has(diff):
			puntajes["time_attack"][diff] = {
				"best_score": 0,
				"name": "---",
				"levels": 0,
				"seconds": 0,
				"precision": 0
			}

	var reg = puntajes["time_attack"][diff_key]
	var best_prev := int(reg.get("best_score", 0))

	if int(totalActual) >= best_prev:
		is_new_record = true
		var nombre_guardado = str(reg.get("name", "---"))
		puntajes["time_attack"][diff_key] = {
			"best_score": int(totalActual),
			"name": nombre_guardado,
			"levels": int(Score.levels_completed),
			"seconds": int(Score.time_attack_seconds),
			"precision": int(Score.perfectBonus)
		}

		var filew = FileAccess.open(path, FileAccess.WRITE)
		filew.store_var(puntajes)
		filew.close()

	Score.latest_total_score = int(totalActual)
	Score.is_new_best = is_new_record


func _dar_pista():
	# 1) Comprobar límite de pistas
	if not _is_practice:
		if pistas_restantes <= 0:
			hints_label.text = "No hints remaining!"
			hints_panel.visible = true
			get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))
			return

		pistas_restantes -= 1
		hints_label.text = str(pistas_restantes) + " Hints Remaining"
	else:
		hints_label.text = "∞ Hints"

	hints_panel.visible = true
	get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))

	# 3) Lógica original de pista (una letra + su caja correcta)
	for i in $Letras.get_children():
		if not i.correct:
			for j in $Ordenada.get_children():
				if j.letter == i.letter and not j.occupied:
					i.hint()
					j.hint()
					return

func nuevaRonda():
	palabraAnterior = palabraES
	palabras.erase(palabraES)

	# Pausar el tiempo durante la animación de nivel completado (también en Time Attack)
	if not _is_practice:
		$Box_inside_game.timer.stop()

	$Letras/Letter.resetVars()
	$Letras/Letter2.resetVars()
	$Letras/Letter3.resetVars()
	$Letras/Letter4.resetVars()

		# Animación final en orden izquierda -> derecha (según su posición actual en la barra)
	var letras := $Letras.get_children()
	letras.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	for l in letras:
		if l.has_method("animacionFinalizado"):
			await l.animacionFinalizado()

	$Letras/Letter.resetPos()
	$Letras/Letter2.resetPos()
	$Letras/Letter3.resetPos()
	$Letras/Letter4.resetPos()

	# Si el tiempo se acabó en medio de la animación, salimos sin iniciar otra ronda
	if _is_time_attack and _ta_finished:
		return

	if _is_time_attack:
		Score.levels_completed += 1
		emit_signal("update_level", str(Score.levels_completed))
		_ta_update_live_score()
	elif _is_practice:
		# Practice: no subimos levels_completed ni rondaActual, no necesitamos update_level
		pass
	else:
		rondaActual += 1
		emit_signal("update_level", "%d/%d" % [rondaActual, rondas])

	await setLetters()

	# Si TA ya terminó, no reanudar
	if not _is_practice and not (_is_time_attack and _ta_finished):
		$Box_inside_game.timer.start()


func actualizar_velocidad():
	var tiempoFinal = $Box_inside_game.time_seconds
	if tiempoFinal > tiempoCronometro / 1.8:
		velocidad += 80
	elif tiempoFinal > tiempoCronometro / 2:
		velocidad += 60
	elif tiempoFinal > tiempoCronometro / 4:
		velocidad += 40
	else:
		velocidad += 0

func _hide_hints_panel():
	hints_panel.visible = false
