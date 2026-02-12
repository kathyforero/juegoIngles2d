extends Node2D

#Signals
#Señales para actualizar titulos y demás características del juego
signal set_timer()
signal update_title(new_title)
signal update_difficulty(new_difficulty)
signal update_level(new_level)
signal uptate_imagen_game(new_image)
#signal set_visible_word(new_word)
signal set_visible_sentence(new_sentence)
signal update_phrase()

#Precarga de modales de victoria y tiempo culminado
var pantallaVictoria = preload("res://Escenas/PantallaVictoria.tscn")
var pantallaTimeAttackFin = preload("res://Escenas/PantallaTimeAttackFin.tscn")

var pantallaAcaboTiempo = preload("res://Escenas/NivelFinalizado.tscn")
var difuminado = preload("res://Piezas/ColorRectDifuminado.tscn")
var instance

@onready var hints_panel = $HintsPanel
@onready var hints_label = $HintsPanel/Label
var pistas_restantes := 5

var en: bool = false

const HINT_COOLDOWN_SEC := 3
var _hint_on_cooldown: bool = false
var _hint_disabled_by_cooldown: bool = false

func _load_language_setting() -> bool:
	if FileAccess.file_exists("user://language_setting.json"):
		var json_as_text := FileAccess.get_file_as_string("user://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return bool(data["english"])
	return false  # default ES

func _hint_no_remaining() -> String:
	return "No hints remaining!" if en else "¡No quedan pistas!"

func _hint_remaining(n: int) -> String:
	return (str(n) + " Hints Remaining") if en else ("Quedan " + str(n) + " pistas")

func _hint_infinite() -> String:
	return "∞ Hints" if en else "∞ Pistas"

func _set_hint_button_disabled(disabled: bool) -> void:
	var btn := $Box_inside_game.get_node_or_null("btns_inside_box_game/btn_instructions")
	if not btn:
		return
	btn.disabled = disabled
	var c: Color = btn.modulate
	c.a = 0.25 if disabled else 1.0
	btn.modulate = c

func _start_hint_cooldown() -> void:
	_hint_on_cooldown = true
	_hint_disabled_by_cooldown = false

	var btn := $Box_inside_game.get_node_or_null("btns_inside_box_game/btn_instructions")
	if btn and not btn.disabled:
		_set_hint_button_disabled(true)
		_hint_disabled_by_cooldown = true

	get_tree().create_timer(HINT_COOLDOWN_SEC).connect("timeout", Callable(self, "_end_hint_cooldown"))

func _end_hint_cooldown() -> void:
	_hint_on_cooldown = false

	if _hint_disabled_by_cooldown and not _ta_finished:
		var can_enable := _is_practice or pistas_restantes > 0
		if can_enable:
			_set_hint_button_disabled(false)

	_hint_disabled_by_cooldown = false


var _hint_flash_tween: Tween

func _flash_hint_button_error() -> void:
	var btn := $Box_inside_game.get_node_or_null("btns_inside_box_game/btn_instructions")
	if btn == null:
		return
	if btn.disabled:
		return

	if _hint_flash_tween and _hint_flash_tween.is_running():
		_hint_flash_tween.kill()

	var base_rgb := Color(btn.modulate.r, btn.modulate.g, btn.modulate.b, 1.0)
	btn.set_meta("_hint_flash_base_rgb", base_rgb)

	var flash := Color(1.0, 0.8, 0.25, btn.modulate.a)
	btn.modulate = flash

	_hint_flash_tween = create_tween()
	_hint_flash_tween.tween_interval(1.0)
	_hint_flash_tween.tween_callback(Callable(self, "_restore_hint_button_modulate").bind(btn))

func _restore_hint_button_modulate(btn: CanvasItem) -> void:
	if btn == null:
		return
	var base_rgb: Color = btn.get_meta("_hint_flash_base_rgb", Color(1, 1, 1))
	var a := 0.25 if btn.disabled else 1.0
	btn.modulate = Color(base_rgb.r, base_rgb.g, base_rgb.b, a)


#Ruta donde se encuentra el ejecutable
var ejecutablePath = Global.rutaArchivos
#var palabra ="bird"

#Variables para manejar las instancias de los modales
var instantiated = false
var instanceAcaboTiempo
var instantiatedAcaboTiempo = false
var instanceDifuminado
var instantiatedDifuminado = false

#Variables para llevar la lógica de rondas y ganar en el juego. Banco donde se encuntran las frases para el puzzle
var gano = false
var ganoRonda = false
var palabrasEsp = BancoPuzzle.palabrasEsp
var cadenas = BancoPuzzle.cadenas
var cadenasOrdenadas = BancoPuzzle.cadenasOrdenadas
var images = BancoPuzzle.images
var indicesImages = []
var indiceNivel = -1
var indiceImagen = 0
var indiceCadena = 0
var estadoInicialPiezas = []
var rondas = 4
var numeroRondas = 0
var precisionMinima = 20

var _precisionActual: int = 100

var precisionActual: int:
	get:
		return _precisionActual
	set(value):
		_precisionActual = value
		if _is_time_attack:
			_ta_update_live_score()

var velocidad = 20
var valorNivel = 100 
var tiempoCronometro = 120 

# --- TIME ATTACK (Contrarreloj) ---
var _is_time_attack: bool = false
var _ta_finished: bool = false

var _is_practice: bool = false

var _ta_live_score_last: int = 0

func _ta_update_live_score(force_delta_zero: bool = false) -> void:
	if not _is_time_attack:
		return

	var new_score := Score.calc_time_attack_score(
		Score.levels_completed,
		Score.time_attack_seconds,
		int(precisionActual)
	)

	var delta := 0 if force_delta_zero else (new_score - _ta_live_score_last)
	_ta_live_score_last = new_score

	if $Box_inside_game and $Box_inside_game.has_method("set_time_attack_score"):
		$Box_inside_game.set_time_attack_score(new_score, delta)


# Muestra instrucciones, actualiza titulos e instancia variables. Empieza ronda
func _ready():
	_is_time_attack = (Score.current_mode == Score.Mode.TIME_ATTACK)
	_is_practice = (Score.current_mode == Score.Mode.PRACTICE)
	_ta_finished = false
	en = _load_language_setting()
	

	# Si venimos desde Time Attack Config, el tiempo se toma de Score.time_attack_seconds
	if _is_time_attack:
		tiempoCronometro = int(Score.time_attack_seconds)
		Score.levels_completed = 0
		Score.fastBonus = 0

	for i in range(BancoPuzzle.exercises.size()):
		indicesImages.append(i)
		
	Score.perfectBonus = 0
	instance = pantallaVictoria.instantiate()
	instantiated = true
	instanceAcaboTiempo = pantallaAcaboTiempo.instantiate()
	instantiatedAcaboTiempo = true
	instanceDifuminado = difuminado.instantiate()
	instantiatedDifuminado = true
	
	# 1) Configurar el tiempo según la dificultad actual
	$Box_inside_game.time_seconds = tiempoCronometro
	
	# 2) Ahora sí, arrancar el cronómetro y configurar UI
	if not _is_practice:
		emit_signal("set_timer")

	emit_signal("update_title", "Puzzle")
	setDifficultTitle()
	
	for i in range(3):
		var pieza = $Cadenas.get_node("Pieza" + str(i))
		estadoInicialPiezas.append({"position": pieza.position})

	_empezar_ronda()
	if _is_time_attack:
		_ta_update_live_score(true)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func setDifficultTitle():
	match Score.actualDifficult:
		Score.difficult["easy"]:
			emit_signal("update_difficulty", "Easy")
		Score.difficult["medium"]:
			emit_signal("update_difficulty", "Medium")
		Score.difficult["hard"]:
			emit_signal("update_difficulty", "Difficult")
		
#Verifica si el jugador ha ganado la ronda o el juego
func _process(_delta):
	if(instantiated):
		# --- TIME ATTACK: loop infinito de niveles hasta que se acabe el tiempo ---
		if _is_time_attack:
			if _ta_finished:
				return
			if ($Cadenas/Pieza0.correct and $Cadenas/Pieza1.correct and $Cadenas/Pieza2.correct and !ganoRonda):
				ganoRonda = true
				Score.levels_completed += 1
				emit_signal("update_level", str(Score.levels_completed))
				_ta_update_live_score()
				rondaWin_time_attack()
			return
		
		# --- PRACTICE: loop infinito sin victory, sin records ---
		if _is_practice:
			if ($Cadenas/Pieza0.correct and $Cadenas/Pieza1.correct and $Cadenas/Pieza2.correct and !ganoRonda):
				ganoRonda = true
				rondaWin_time_attack()  # reutiliza el reinicio + nueva ronda
			return

		if ($Cadenas/Pieza0.correct and $Cadenas/Pieza1.correct and
		  	$Cadenas/Pieza2.correct and numeroRondas == rondas and !gano):
			gano = true
			victory()
		elif ($Cadenas/Pieza0.correct and $Cadenas/Pieza1.correct and
		  	$Cadenas/Pieza2.correct and numeroRondas < rondas and !ganoRonda and !gano):
			ganoRonda = true
			numeroRondas+=1
			if(numeroRondas < rondas):		
				rondaWin()
			
	pass

#Se invoca al empezar una nueva ronda
func _empezar_ronda():		
	indiceNivel += 1
	# Recargar banco de imágenes si ya no alcanza (útil en Time Attack)
	if indicesImages.size() <= 0:
		for i in range(BancoPuzzle.exercises.size()):
			indicesImages.append(i)
	var indiceAl = randi_range(0, indicesImages.size()-1)
	indiceImagen = indicesImages[indiceAl]
	indicesImages.remove_at(indiceAl)
	print(str(indiceImagen))
	indiceCadena = randi_range(0, cadenas[indiceImagen].size()-1)
	print(str(indiceCadena))
	emit_signal("set_visible_sentence", palabrasEsp[indiceImagen][indiceCadena])
	if _is_time_attack:
		emit_signal("update_level", str(Score.levels_completed))
	else:
		emit_signal("update_level", str(indiceNivel+1)+"/"+str(rondas))
	emit_signal("uptate_imagen_game", images[indiceImagen])
	update_boxes(indiceCadena)
	ganoRonda=false

#Reinicia los objetos al empezar una ronda
func _reiniciar_componentes():
	var x=0
	for dicc in estadoInicialPiezas:
		var pieza = $Cadenas.get_node("Pieza"+str(x))
		var piezaBox = $Ordenada.get_node("piezaBox"+str(x))
		pieza.position = dicc["position"]
		pieza._reiniciar_variables()
		piezaBox._reiniciar_variables()
		x+=1
	_animacion_retorno()
	if _is_time_attack and _ta_finished:
		return
	_empezar_ronda()

#Quita los colores de correcto de las piezas con una animación
func _animacion_retorno():
	for i in range(3):
		var pieza = $Cadenas.get_node("Pieza"+str(i))
		pieza._animacion_retorno()
	
#Da pista tomando en cuenta las píezas que no han sido puestas
func _dar_pista():
	if _hint_on_cooldown:
		return
	_start_hint_cooldown()

	if not _is_practice:
		if pistas_restantes <= 0:
			hints_label.text = _hint_no_remaining()
			hints_panel.visible = true
			get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))
			_set_hint_button_disabled(true)
			return

		pistas_restantes -= 1
		hints_label.text = _hint_remaining(pistas_restantes)
	else:
		hints_label.text = _hint_infinite()

	hints_panel.visible = true
	get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))

	var numeros = [0, 1, 2]
	while numeros.size() > 0:
		var indice_aleatorio = randi() % numeros.size()
		var numero_seleccionado = numeros[indice_aleatorio]
		var pieza = "Pieza" + str(numero_seleccionado)
		var nodePieza = $Cadenas.get_node(pieza)
		if not nodePieza.correct:
			var posicionCadena = cadenasOrdenadas[indiceImagen][indiceCadena].find(nodePieza.letter)
			var piezaBox = "piezaBox" + str(posicionCadena)
			var nodePiezaBox = $Ordenada.get_node(piezaBox)
			nodePieza._animacion_pista()
			nodePiezaBox._animacion_pista()
			return
		numeros.remove_at(indice_aleatorio)
		

func _hide_hints_panel():
	hints_panel.visible = false

#Actualiza la textura y texto en las piezas
func update_boxes(index: int):
	cadenas[indiceImagen][index].shuffle()
	var x=0	
	for cadena in cadenas[indiceImagen][index]:
		var nombrePieza = "Pieza"+str(x)
		var nombrePiezaBox = "piezaBox"+str(x)
		var pieza_objetivo = get_node("Cadenas/"+nombrePieza)
		pieza_objetivo.letter = cadena
		var pieza_box_objetivo = get_node("Ordenada/"+nombrePiezaBox)
		pieza_box_objetivo.letter = cadenasOrdenadas[indiceImagen][index][x]
		x+=1
		var posicion = cadenasOrdenadas[indiceImagen][index].find(cadena)
		var sprite_pz_objetivo = get_node("Cadenas/"+nombrePieza+"/InteractivoLetra(vacio)")
		cargar_nueva_textura(sprite_pz_objetivo, posicion)
		
	emit_signal("update_phrase")
		
#Actualiza textura en una pieza
func cargar_nueva_textura(sprite, index):
	var nueva_textura
	if index==0:
		nueva_textura = load("res://Sprites/mini_games/pieza3.png")
	elif index==1:
		nueva_textura = load("res://Sprites/mini_games/pieza1.png")
	else:
		nueva_textura = load("res://Sprites/mini_games/pieza2.png")
	sprite.texture = nueva_textura

#Actualiza el bonus de velocidad según el cronómetro
func _actualizar_velocidad():
	var tiempoFinal = $Box_inside_game.time_seconds
	if (tiempoFinal >  tiempoCronometro/1.8):
		velocidad+=80
	elif (tiempoFinal >  tiempoCronometro/2):
		velocidad+=60
	elif (tiempoFinal >  tiempoCronometro/4):
		velocidad+=40
	else:
		velocidad+=0
	var content = {"niveles": valorNivel, "velocidad": velocidad}

func _actualizar_puntajes(path):
	var totalActual = velocidad + precisionActual + valorNivel
	var is_new_record := false
	var diff_key := "easy"  # este script es SOLO para Easy

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var puntajes = file.get_var()
		file.close()

		# Asegurar que existan las 3 dificultades
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
				"name": nombre_guardado
			}

			var new_file = FileAccess.open(path, FileAccess.WRITE)
			new_file.store_var(puntajes)
			new_file = null
	else:
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

	# Actualizamos flags globales
	Score.latest_total_score = totalActual
	Score.is_new_best = is_new_record

#Guarda los puntajes en el archivo

func _actualizar_puntajes_time_attack(path:String, totalActual:int) -> void:
	var is_new_record := false
	var diff_key := "easy" # este script es EASY

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

	if totalActual >= best_prev:
		is_new_record = true
		var nombre_guardado = str(reg.get("name", "---"))
		puntajes["time_attack"][diff_key] = {
			"best_score": totalActual,
			"name": nombre_guardado,
			"levels": int(Score.levels_completed),
			"seconds": int(Score.time_attack_seconds),
			"precision": int(precisionActual)
		}

		var filew = FileAccess.open(path, FileAccess.WRITE)
		filew.store_var(puntajes)
		filew.close()

	Score.latest_total_score = totalActual
	Score.is_new_best = is_new_record

func _guardar_puntajes(content, path):
	var file = FileAccess.open(path ,FileAccess.WRITE)
	file.store_var(content)
	file = null

func actualizar_progreso(path):
	if FileAccess.file_exists(path):  # Verifica si el archivo existe  
		var file = FileAccess.open(path, FileAccess.READ)# Abre el archivo en modo lectura
		var progreso = file.get_var()
		file = null
		var esPrimeraVez = false
		match Score.actualDifficult:
			Score.difficult["easy"]:
				if (progreso["puzzle"]["medium"] && progreso["puzzle"]["firstMedium"] == false):
					esPrimeraVez = false
				else:
					esPrimeraVez = true		
					progreso["puzzle"]["medium"] = true
					progreso["puzzle"]["firstMedium"] = true				
			Score.difficult["medium"]:
				if (progreso["puzzle"]["hard"] && progreso["puzzle"]["firstHard"] == false):
					esPrimeraVez = false
				else:
					esPrimeraVez = true		
					progreso["puzzle"]["hard"] = true
					progreso["puzzle"]["firstHard"] = true
		if(esPrimeraVez):	
			if DirAccess.remove_absolute(path) == OK:	 
				print("Archivo PROGRESO existente borrado.")
				var new_file = FileAccess.open(path ,FileAccess.WRITE)
				new_file.store_var(progreso)
				new_file = null
			else:
				print("Error al intentar borrar el archivo PROGRESO.")
		
#Se invoca cuando el jugador gana
func finish_time_attack() -> void:
	if not _is_time_attack:
		return
	if _ta_finished:
		return
	_ta_finished = true

	# Parar timer HUD para evitar dobles llamadas
	$Box_inside_game.timer.stop()
	$Box_inside_game/btns_inside_box_game/btn_instructions.disabled = true

	# Score: niveles completados + tiempo escogido (base) + precisión (bonus)
	Score.LatestGame = Score.Games.Puzzle
	Score.fastBonus = 0

	var precision_bonus := int(precisionActual)
	if Score.levels_completed <= 0:
		precision_bonus = 0
		precisionActual = 0

	Score.perfectBonus = precision_bonus

	var total := Score.calc_time_attack_score(Score.levels_completed, Score.time_attack_seconds, precision_bonus)
	var base := total - precision_bonus
	if base < 0:
		base = 0

	Score.newScore = base
	Score.latest_total_score = total

	# Guardado por modo/dificultad (Time Attack)
	_actualizar_puntajes_time_attack(ejecutablePath + "/Scores/puntajesPuzzle.dat", total)

	instance = pantallaTimeAttackFin.instantiate()
	_lock_interaction_time_over_puzzle()
	_show_time_over_overlay()


func _lock_interaction_time_over_puzzle() -> void:
	# Bloquea piezas (piezaPuzzle.gd ya respeta locked/dragging)
	if has_node("Cadenas"):
		for p in $Cadenas.get_children():
			if p == null:
				continue
			if p.get("dragging") != null:
				p.dragging = false
			if p.get("locked") != null:
				p.locked = true

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
	instance.position = Vector2(1000,0)
	$AnimationPlayer.play("Gana")
	await $AnimationPlayer.animation_finished

	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instance)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	$AudioStreamPlayer2D.play()
	while(instance.position.x > 0):
		await get_tree().create_timer(0.000000001).timeout
		instance.position.x-=50


func victory():
	if _is_practice:
		return

	instance.position = Vector2(1000,0)
	$Box_inside_game.timer.stop()
	_actualizar_velocidad()
	_actualizar_puntajes(ejecutablePath+"/Scores/puntajesPuzzle.dat")
	actualizar_progreso(ejecutablePath+"/Progress/progressMinigames.dat")
	var totalActual = velocidad+precisionActual+valorNivel
	print("Velocidad: "+str(velocidad)+", "+"Precision: "+str(precisionActual)+", "+"Niveles: "+str(valorNivel)+", Total: "+str(totalActual))
	Score.newScore = valorNivel
	Score.fastBonus = velocidad
	Score.perfectBonus = precisionActual
	Score.LatestGame = Score.Games.Puzzle
	var time_spent = max(0.0, float(tiempoCronometro) - float($Box_inside_game.time_seconds))
	var is_perfect := int(precisionActual) >= 100
	Score.register_minigame_victory("puzzle", Score.actualDifficult, time_spent, is_perfect, false)

	var ordenCorrecto = cadenasOrdenadas[indiceImagen][indiceCadena]
	for i in range(ordenCorrecto.size()):
		var palabra = ordenCorrecto[i]
		for j in range(3):
			var pieza = $Cadenas.get_node("Pieza" + str(j))
			if pieza.correct and (pieza.target_letter == palabra or pieza.letter == palabra):
				await pieza._animacion_finalizado()
				if i < ordenCorrecto.size() - 1:
					await get_tree().create_timer(0.05).timeout
				break

	$AnimationPlayer.play("Gana")
	await $AnimationPlayer.animation_finished
	$AudioStreamPlayer2D.play()
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instance)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	while(instance.position.x > 0):
		await get_tree().create_timer(0.000000001).timeout
		instance.position.x-=50

#Se invoca cuando se acaba el tiempo
func lose():
	if _is_practice:
		return

	$Box_inside_game.timer.stop()
	get_tree().paused = true
	instanceAcaboTiempo.nombreEscenaDificultad = "Dificultad_Puzzle.tscn"
	instanceAcaboTiempo.position = Vector2(1000,0)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instanceAcaboTiempo)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	while(instanceAcaboTiempo.position.x > 0):
		await get_tree().create_timer(0.000000001).timeout
		instanceAcaboTiempo.position.x-=50

#Se invoca cada vez que se gana una ronda
func rondaWin_time_attack():
	# 1) PAUSA SOLO durante la animación
	if not _is_practice:
		$Box_inside_game.timer.stop()
	$AnimationPlayer.play("Gana")

	var ordenCorrecto = cadenasOrdenadas[indiceImagen][indiceCadena]
	for i in range(ordenCorrecto.size()):
		var palabra = ordenCorrecto[i]
		for j in range(3):
			var pieza = $Cadenas.get_node("Pieza" + str(j))
			if pieza.correct and (pieza.target_letter == palabra or pieza.letter == palabra):
				await pieza._animacion_finalizado()
				if i < ordenCorrecto.size() - 1:
					await get_tree().create_timer(0.05).timeout
				break

	await $AnimationPlayer.animation_finished
	# 2) REANUDA si todavía seguimos en TA
	if not _ta_finished and not _is_practice:
		$Box_inside_game.timer.start()
	await _reiniciar_componentes()
	ganoRonda = false

	
func rondaWin():
	$Box_inside_game.timer.stop()
	$AnimationPlayer.play("Gana")

	var ordenCorrecto = cadenasOrdenadas[indiceImagen][indiceCadena]
	for i in range(ordenCorrecto.size()):
		var palabra = ordenCorrecto[i]
		for j in range(3):
			var pieza = $Cadenas.get_node("Pieza" + str(j))
			if pieza.correct and (pieza.target_letter == palabra or pieza.letter == palabra):
				await pieza._animacion_finalizado()
				if i < ordenCorrecto.size() - 1:
					await get_tree().create_timer(0.05).timeout
				break

	await $AnimationPlayer.animation_finished
	await _reiniciar_componentes()
	$Box_inside_game.timer.start()
	
#Botón para regresar al menú
func _on_btn_go_back_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")
