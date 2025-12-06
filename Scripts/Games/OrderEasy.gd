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

func _ready():
	Score.perfectBonus = 100
	_cargar_palabras_desde_banco_easy()

	emit_signal("set_timer")
	emit_signal("update_title", "Order it")
	setDifficultTitle()
	emit_signal("update_level", "1/" + str(rondas))

	instance = pantallaVictoria.instantiate()
	instantiated = true
	instanceAcaboTiempo = pantallaAcaboTiempo.instantiate()
	instantiatedAcaboTiempo = true
	instanceDifuminado = difuminado.instantiate()
	instantiatedDifuminado = true

	setLetters()
	tiempoCronometro = $Box_inside_game.time_seconds

func _process(_delta):
	if instantiated:
		if ($Letras/Letter.correct and $Letras/Letter2.correct and
			$Letras/Letter3.correct and $Letras/Letter4.correct and
			rondaActual == rondas and !gano):
			gano = true
			victory()
		if ($Letras/Letter.correct and $Letras/Letter2.correct and
			$Letras/Letter3.correct and $Letras/Letter4.correct):
			if rondaActual < rondas:
				await nuevaRonda()
			else:
				gano = true

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
	$Box_inside_game.timer.stop()
	actualizar_velocidad()
	_actualizar_puntajes(ejecutablePath + "/Scores/puntajesOrder.dat")

	var totalActual = velocidad + Score.perfectBonus + valorNivel
	Score.newScore = valorNivel
	Score.fastBonus = velocidad
	# Score.perfectBonus ya viene modificado por Letter.gd
	Score.LatestGame = Score.Games.OrderIt
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

func _dar_pista():
	# 1) Comprobar límite de pistas
	if pistas_restantes <= 0:
		hints_label.text = "No hints remaining!"
		hints_panel.visible = true
		get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))
		return

	# 2) Descontar y mostrar contador
	pistas_restantes -= 1
	hints_label.text = str(pistas_restantes) + " Hints Remaining"
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
	$Box_inside_game.timer.stop()
	$Letras/Letter.resetVars()
	$Letras/Letter2.resetVars()
	$Letras/Letter3.resetVars()
	$Letras/Letter4.resetVars()
	await $Letras/Letter.animacionFinalizado()
	await $Letras/Letter2.animacionFinalizado()
	await $Letras/Letter3.animacionFinalizado()
	await $Letras/Letter4.animacionFinalizado()
	$Letras/Letter.resetPos()
	$Letras/Letter2.resetPos()
	$Letras/Letter3.resetPos()
	$Letras/Letter4.resetPos()
	rondaActual += 1
	emit_signal("update_level", "%d/%d" % [rondaActual, rondas])
	await setLetters()
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
