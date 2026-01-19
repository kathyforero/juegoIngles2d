extends Node2D

# Señales que se emiten para actualizar diferentes aspectos de la escena, título, dificultad, nivel y visibilidad de las imágenes.
signal update_scene(path)
signal update_title(new_title)
signal set_timer()
signal update_difficulty(new_difficulty)
signal update_level(new_level)
signal set_not_visible_image()

var ejecutablePath = Global.rutaArchivos
var arrows = {}  # key: value de la imagen, value: { line, imagen, texto }

# Variables para el control del nivel, dificultad, título, rondas, y otras propiedades del juego.
var level = 1
var difficulty = 'easy'
var title = "match it"
var rondas = 4  # Número total de rondas (solo modo clásico).
var numeroRondas = 1  # Ronda actual.
var ganoRonda = false  # Indica si se ha ganado una ronda.

# Variables para precisión, velocidad, y cronómetro.
var precisionMinima = 20
var precisionActual = 100
var velocidad = 20
var valorNivel = 100
var tiempoCronometro = 120  # Tiempo en segundos del cronómetro.

# Variables para Time Attack
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

# Variables para las imágenes seleccionadas.
var selected_image: Node2D = null  # Imagen actualmente seleccionada.

var animals = {}
var images = []
var names = []
var shufflednames= []

# Referencias a nodos en la escena.
@onready var box_imagen_match = $Box_imagen_match
@onready var box_imagen_match_2 = $Box_imagen_match2
@onready var box_imagen_match_3 = $Box_imagen_match3
@onready var box_texto_match = $Box_texto_match
@onready var box_texto_match_2 = $Box_texto_match2
@onready var box_texto_match_3 = $Box_texto_match3
@onready var hints_panel = $HintsPanel
@onready var hints_label = $HintsPanel/Label

var en: bool = false

const HINT_COOLDOWN_SEC := 3
var _hint_on_cooldown: bool = false
var _hint_disabled_by_cooldown: bool = false

func _load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text := FileAccess.get_file_as_string("res://language_setting.json")
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

	# Solo re-habilitar si fue deshabilitado por cooldown,
	# no estamos en fin de time attack y aún hay pistas (o es practice).
	if _hint_disabled_by_cooldown and not _ta_finished:
		var can_enable := _is_practice or pistas_restantes > 0
		if can_enable:
			_set_hint_button_disabled(false)

	_hint_disabled_by_cooldown = false


@onready var _fx_ok: Sprite2D = $Correct
@onready var _fx_bad: Sprite2D = $Incorrect
@onready var _fx_anim: AnimationPlayer = $AnimationPlayer

var _fx_ok_scale0: Vector2
var _fx_bad_scale0: Vector2
var _fx_bad_offset0: Vector2

# Variables para controlar el estado de las instancias en la escena.
var instantiated: bool = false
var gano: bool = false
var pantallaVictoria = preload("res://Escenas/PantallaVictoria.tscn")
var pantallaTimeAttackFin = preload("res://Escenas/PantallaTimeAttackFin.tscn")

var instance
var pantallaAcaboTiempo = preload("res://Escenas/NivelFinalizado.tscn")
var difuminado = preload("res://Piezas/ColorRectDifuminado.tscn")
var instanceAcaboTiempo
var instantiatedAcaboTiempo = false
var instanceDifuminado
var instantiatedDifuminado = false

# Método llamado cuando el nodo entra en la escena por primera vez.
func _ready():
	_is_time_attack = (Score.current_mode == Score.Mode.TIME_ATTACK)
	_is_practice = (Score.current_mode == Score.Mode.PRACTICE)
	_ta_finished = false
	en = _load_language_setting()

	load_easy_mode_animals()

	# Modo clásico: selecciona 12 (4 rondas x 3)
	# Time Attack: selecciona 3 para la primera ronda (y luego se recarga infinito)
	images.clear()
	names.clear()

	if _is_time_attack:
		tiempoCronometro = int(Score.time_attack_seconds)
		Score.levels_completed = 0
		Score.fastBonus = 0
		_preparar_3_animales_para_ronda_time_attack()
	elif _is_practice:
		# Practice usa el generador infinito (tipo TA) pero sin tocar scores
		_preparar_3_animales_para_ronda_time_attack()
	else:
		assign_images_and_names()


	# 1) Tiempo → HUD
	$Box_inside_game.time_seconds = tiempoCronometro

	# 2) HUD + textos
	if not _is_practice:
		emit_signal("set_timer")
	emit_signal("update_scene", "menu_juegos")
	emit_signal("update_title", title)
	setDifficultTitle()
	emit_signal("update_level", _texto_nivel_ui())
	emit_signal("set_not_visible_image")

	# 3) Instanciar escenas necesarias
	instance = pantallaVictoria.instantiate()
	instantiated = true
	instanceAcaboTiempo = pantallaAcaboTiempo.instantiate()
	instantiatedAcaboTiempo = true
	instanceDifuminado = difuminado.instantiate()
	instantiatedDifuminado = true

	# 4) Empezar juego
	hints_panel.visible = false
	_ta_update_live_score(true)
	_fx_ok_scale0 = _fx_ok.scale
	_fx_bad_scale0 = _fx_bad.scale
	_fx_bad_offset0 = _fx_bad.offset
	_reset_feedback_fx()

	iniciar_juego()

# Load the data from MatchIt.json for easy mode
func load_easy_mode_animals():
	animals.clear()
	# Tomar el banco ya cargado en memoria
	if BancoMatchIt.easy.is_empty():
		push_error("BancoMatchIt.easy is empty. Check Banco_MatchIt.gd / Banco_MatchIt.json.")
		return
	animals = BancoMatchIt.easy.duplicate(true)

func assign_images_and_names():
	var keys = animals.keys()
	if keys.size() < 12:
		print("Not enough animals left for a round.")
		return

	# Barajar el array de claves para que el orden sea realmente aleatorio
	randomize()
	keys.shuffle()

	# Pick 12 unique animals for this game
	for i in range(12):
		var selected_key = keys.pop_front()  # ya viene de una lista barajada
		images.append(animals[selected_key])
		names.append(selected_key)
		animals.erase(selected_key)

func _process(_delta):
	if instantiated:
		# --- TIME ATTACK: loop infinito hasta que se acabe el tiempo ---
		if _is_time_attack:
			if _ta_finished:
				return

			if box_texto_match.is_matched() and box_texto_match_2.is_matched() and box_texto_match_3.is_matched() and !ganoRonda:
				ganoRonda = true
				Score.levels_completed += 1
				_ta_update_live_score()
				ronda_win_time_attack()
			return
		
		# --- PRACTICE: loop infinito sin timer, sin score/records ---
		if _is_practice:
			if box_texto_match.is_matched() and box_texto_match_2.is_matched() and box_texto_match_3.is_matched() and !ganoRonda:
				ganoRonda = true
				ronda_win_time_attack() # reutilizamos el loop, pero abajo lo “des-timerizamos”
			return

		# --- CLÁSICO: tu lógica intacta ---
		if (box_texto_match.is_matched() and box_texto_match_2.is_matched() and
		box_texto_match_3.is_matched() and numeroRondas == rondas+1 and !gano):
			gano = true
			victory()
		elif (box_texto_match.is_matched() and box_texto_match_2.is_matched() and
		 box_texto_match_3.is_matched() and numeroRondas < rondas+1 and !ganoRonda and !gano):
			ganoRonda = true
			numeroRondas += 1
			if numeroRondas <= rondas:
				ronda_win()

# Método para establecer el texto de dificultad
func setDifficultTitle():
	match Score.actualDifficult:
		Score.difficult["easy"]:
			emit_signal("update_difficulty", "Easy")
		Score.difficult["medium"]:
			emit_signal("update_difficulty", "Medium")
		Score.difficult["hard"]:
			emit_signal("update_difficulty", "Difficult")

# Método para manejar la imagen seleccionada.
func handle_value_selected(node):
	if selected_image and not node == selected_image:
		selected_image.fondo_clic.visible = false
	selected_image = node

# Método para manejar el emparejamiento de valores.
func handle_value_match(target_node):
	if !selected_image:
		target_node.fondo_clic.visible = false
		return
	if selected_image.value == target_node.target:
		selected_image.blocked = true
		target_node.blocked = true
		selected_image.animation_match()
		target_node.animation_match()
		target_node.mark_to_match()
		_play_feedback_fx(true)
		crear_flecha(selected_image, target_node)
	else:
		if precisionActual > precisionMinima:
			precisionActual -= 10
			_ta_update_live_score()
		selected_image.animation_no_match()
		target_node.animation_no_match()
		selected_image.fondo_clic.visible = false
		_play_feedback_fx(false)
	selected_image = null

func _reset_feedback_fx() -> void:
	# Corta cualquier animación en curso (esto evita estados “a medias”)
	if _fx_anim and _fx_anim.is_playing():
		_fx_anim.stop()

	# Reset OK
	_fx_ok.visible = false
	_fx_ok.modulate.a = 0.0
	_fx_ok.scale = _fx_ok_scale0

	# Reset X
	_fx_bad.visible = false
	_fx_bad.modulate.a = 0.0
	_fx_bad.scale = _fx_bad_scale0
	_fx_bad.offset = _fx_bad_offset0


func _play_feedback_fx(is_correct: bool) -> void:
	_reset_feedback_fx()

	if is_correct:
		_fx_ok.visible = true
		_fx_anim.play("correct")
	else:
		_fx_bad.visible = true
		_fx_anim.play("incorrect")

	# Asegura que aplique el frame 0 ya mismo (por si venías de otra animación)
	_fx_anim.seek(0.0, true)

# Texto de nivel para UI (clásico: 1/4, TA: niveles completados)
func _texto_nivel_ui() -> String:
	if _is_time_attack:
		return str(Score.levels_completed)
	return str(numeroRondas) + "/4"

# Método para iniciar el juego.
func iniciar_juego():
	eliminar_todas_las_flechas()
	emit_signal("update_level", _texto_nivel_ui())

	# TIME ATTACK: ya tenemos 3 en images/names
	if _is_time_attack:
		_set_round_content(images, names)
		ganoRonda = false
		return

	# CLÁSICO: primera ronda con los primeros 3
	var image_name_pairs = []
	for i in range(3):
		image_name_pairs.append({"image": images[i], "name": names[i]})
	randomize()
	image_name_pairs.shuffle()

	var shuffled_names = names.slice(0, 3).duplicate()
	shuffled_names.shuffle()

	box_imagen_match.put_image(image_name_pairs[0]["image"], image_name_pairs[0]["name"])
	box_imagen_match_2.put_image(image_name_pairs[1]["image"], image_name_pairs[1]["name"])
	box_imagen_match_3.put_image(image_name_pairs[2]["image"], image_name_pairs[2]["name"])
	box_texto_match.put_text(shuffled_names[0])
	box_texto_match_2.put_text(shuffled_names[1])
	box_texto_match_3.put_text(shuffled_names[2])
	ganoRonda = false

# Método para cargar una nueva ronda.
func cargar_ronda():
	reset_compoments()
	eliminar_todas_las_flechas()

	# TIME ATTACK: siempre recarga 3 nuevos
	if _is_time_attack:
		_preparar_3_animales_para_ronda_time_attack()
		emit_signal("update_level", _texto_nivel_ui())
		_set_round_content(images, names)
		ganoRonda = false
		return

	# PRACTICE: igual que TA (3 nuevos siempre), sin update de nivel obligatorio
	if _is_practice:
		_preparar_3_animales_para_ronda_time_attack()
		_set_round_content(images, names)
		ganoRonda = false
		return

	# CLÁSICO: ronda 2..4 en base a índices
	emit_signal("update_level", str(numeroRondas) + "/4")
	var start_index = (numeroRondas - 1) * 3
	var end_index = start_index + 3

	var round_names = names.slice(start_index, end_index)
	var round_images = images.slice(start_index, end_index)

	_set_round_content(round_images, round_names)
	ganoRonda = false

# Asigna imágenes/textos con el mismo método de tu código (shuffle de pares e independiente del texto)
func _set_round_content(round_images:Array, round_names:Array) -> void:
	if round_images.size() < 3 or round_names.size() < 3:
		return

	var image_name_pairs = []
	for i in range(3):
		image_name_pairs.append({"image": round_images[i], "name": round_names[i]})

	randomize()
	image_name_pairs.shuffle()

	var shuffled_names = round_names.duplicate()
	shuffled_names.shuffle()

	var match_boxes = [box_imagen_match, box_imagen_match_2, box_imagen_match_3]
	var text_boxes = [box_texto_match, box_texto_match_2, box_texto_match_3]

	for i in range(3):
		match_boxes[i].put_image(image_name_pairs[i]["image"], image_name_pairs[i]["name"])
		text_boxes[i].put_text(shuffled_names[i])

# TIME ATTACK: preparar 3 animales por ronda, evitando quedarnos sin keys
func _preparar_3_animales_para_ronda_time_attack() -> void:
	images.clear()
	names.clear()

	# Si ya no hay suficientes, recargar banco (permite repetir después, ok para TA)
	if animals.keys().size() < 3:
		load_easy_mode_animals()

	var keys = animals.keys()
	randomize()
	keys.shuffle()

	for i in range(3):
		var k = keys.pop_front()
		names.append(k)
		images.append(animals[k])
		animals.erase(k)

# Método para reiniciar los componentes entre rondas.
func reset_compoments():
	box_imagen_match.animation_reset()
	box_imagen_match_2.animation_reset()
	box_imagen_match_3.animation_reset()
	box_texto_match.animation_reset()
	box_texto_match_2.animation_reset()
	box_texto_match_3.animation_reset()

# Método llamado cuando se gana una ronda (CLÁSICO).
func ronda_win():
	$Box_inside_game/btns_inside_box_game/btn_instructions.disabled = true
	$Box_inside_game.timer.stop()
	await animation_win()
	await cargar_ronda()
	$Box_inside_game.timer.start()
	$Box_inside_game/btns_inside_box_game/btn_instructions.disabled = false

# Método llamado cuando se gana una ronda (TIME ATTACK).
func ronda_win_time_attack():
	$Box_inside_game/btns_inside_box_game/btn_instructions.disabled = true

	# Pausar el tiempo SOLO durante la animación (como en modo normal)
	if not _is_practice:
		$Box_inside_game.timer.stop()

	await animation_win()
	if _ta_finished:
		return

	await cargar_ronda()
	if not _ta_finished and not _is_practice:
		$Box_inside_game.timer.start()

	$Box_inside_game/btns_inside_box_game/btn_instructions.disabled = false

# Método para dar una pista en el juego de manera aleatoria.
var pistas_restantes = 5

func _dar_pista():
	if _hint_on_cooldown:
		return
	_start_hint_cooldown()

	var is_practice := _is_practice  # o: (Score.current_mode == Score.Mode.PRACTICE)

	if not is_practice:
		if pistas_restantes <= 0:
			hints_label.text = _hint_no_remaining()
			hints_panel.visible = true
			get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))
			_set_hint_button_disabled(true) # <- ahora se ve transparente
			print("No quedan más pistas disponibles.")
			return

		pistas_restantes -= 1
		hints_label.text = _hint_remaining(pistas_restantes)
	else:
		# Practice = hints infinitos
		hints_label.text = _hint_infinite()

	hints_panel.visible = true
	get_tree().create_timer(3.0).connect("timeout", Callable(self, "_hide_hints_panel"))

	var imgs = [box_imagen_match, box_imagen_match_2, box_imagen_match_3]
	var words = [box_texto_match, box_texto_match_2, box_texto_match_3]
	var indices_a_eliminar = []
	for i in range(imgs.size()):
		if imgs[i].blocked:
			indices_a_eliminar.append(i)

	indices_a_eliminar.reverse()
	for i in indices_a_eliminar:
		imgs.pop_at(i)

	imgs.shuffle()
	var image_pista = imgs.pop_front()

	for word in words:
		if image_pista.value == word.target:
			image_pista.animation_pista()
			word.animation_pista()

func _hide_hints_panel():
	hints_panel.visible = false

# =========================
# FINISH TIME ATTACK (llamado por HUD cuando el tiempo llega a 0)
# =========================
func finish_time_attack() -> void:
	if not _is_time_attack:
		return
	if _ta_finished:
		return
	_ta_finished = true

	# Parar timer HUD para evitar dobles llamadas
	$Box_inside_game.timer.stop()

	# Congelar input de pistas
	$Box_inside_game/btns_inside_box_game/btn_instructions.disabled = true

	# Score: niveles + tiempo escogido (base) + precisión (bonus)
	Score.LatestGame = Score.Games.MatchIt
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
	_actualizar_puntajes_time_attack(ejecutablePath + "/Scores/puntajesMatch.dat", total)

	instance = pantallaTimeAttackFin.instantiate()
	_lock_interaction_time_over_match()
	_show_time_over_overlay()

func _lock_interaction_time_over_match() -> void:
	# evita clicks y estados raros si quedó algo seleccionado
	selected_image = null

	var nodes := [
		box_imagen_match, box_imagen_match_2, box_imagen_match_3,
		box_texto_match, box_texto_match_2, box_texto_match_3
	]

	for n in nodes:
		if n == null:
			continue
		# Las piezas usan "blocked" para ignorar clicks
		if n.get("blocked") != null:
			n.blocked = true

		# apaga el highlight si quedó encendido
		var fondo = n.get_node_or_null("Button/Fondo_clic")
		if fondo != null:
			fondo.visible = false

func _show_time_over_overlay() -> void:
	# Igual que _show_victory_overlay() pero SIN animation_win()
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


# Método para manejar la victoria del jugador (CLÁSICO).
func victory():
	if _is_practice:
		return

	instance.position = Vector2(1000,0)
	$Box_inside_game.timer.stop()
	_actualizar_velocidad()
	_actualizar_puntajes(ejecutablePath+"/Scores/puntajesMatch.dat")
	actualizar_progreso(ejecutablePath+"/Progress/progressMinigames.dat")
	var totalActual = velocidad+precisionActual+valorNivel
	print("Velocidad: "+str(velocidad)+", "+"Precision: "+str(precisionActual)+", "+"Niveles: "+str(valorNivel)+", Total: "+str(totalActual))
	Score.newScore = valorNivel
	Score.LatestGame = Score.Games.MatchIt
	Score.perfectBonus = precisionActual
	Score.fastBonus = velocidad
	var time_spent = max(0.0, float(tiempoCronometro) - float($Box_inside_game.time_seconds))
	var is_perfect := int(precisionActual) >= 100
	Score.register_minigame_victory("match", Score.actualDifficult, time_spent, is_perfect, false)

	animation_win()
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
		instance.position.x -= 50

func _show_victory_overlay() -> void:
	instance.position = Vector2(1000, 0)
	animation_win()
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

# Método que ejecuta la animación de victoria.
func animation_win():
	$AnimationPlayer.play("Win")
	await $AnimationPlayer.animation_finished

func actualizar_progreso(path):
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var progreso = file.get_var()
		file = null
		var esPrimeraVez = false
		match Score.actualDifficult:
			Score.difficult["easy"]:
				if (progreso["match"]["medium"] && progreso["match"]["firstMedium"] == false):
					esPrimeraVez = false
				else:
					esPrimeraVez = true
					progreso["match"]["medium"] = true
					progreso["match"]["firstMedium"] = true
			Score.difficult["medium"]:
				if (progreso["match"]["hard"] && progreso["match"]["firstHard"] == false):
					esPrimeraVez = false
				else:
					esPrimeraVez = true
					progreso["match"]["hard"] = true
					progreso["match"]["firstHard"] = true
		if esPrimeraVez:
			if DirAccess.remove_absolute(path) == OK:
				print("Archivo PROGRESO existente borrado.")
				var new_file = FileAccess.open(path ,FileAccess.WRITE)
				new_file.store_var(progreso)
				new_file = null
			else:
				print("Error al intentar borrar el archivo PROGRESO.")

# Método que se ejecuta cuando el jugador pierde o se detiene el cronometro.
func lose():
	if _is_practice:
		return

	# En Time Attack no mostramos "se acabó el tiempo": eso lo maneja finish_time_attack()
	if _is_time_attack:
		finish_time_attack()
		return

	$Box_inside_game.timer.stop()
	get_tree().paused = true
	instanceAcaboTiempo.nombreEscenaDificultad = "Dificultad_MatchIt.tscn"
	instanceAcaboTiempo.position = Vector2(1000,0)
	var canvas_layer = CanvasLayer.new()
	canvas_layer.add_child(instanceDifuminado)
	var canvas_layer1 = CanvasLayer.new()
	canvas_layer1.add_child(instanceAcaboTiempo)
	add_child(canvas_layer)
	add_child(canvas_layer1)
	while instanceAcaboTiempo.position.x > 0:
		await get_tree().create_timer(0.000000001).timeout
		instanceAcaboTiempo.position.x -= 50

# Método para actualizar la velocidad del jugador basado en el tiempo restante.
func _actualizar_velocidad():
	var tiempoFinal = $Box_inside_game.time_seconds
	if (tiempoFinal >  tiempoCronometro/1.8):
		velocidad += 80
	elif (tiempoFinal >  tiempoCronometro/2):
		velocidad += 60
	elif (tiempoFinal >  tiempoCronometro/4):
		velocidad += 40
	else:
		velocidad += 0
	var content = {"niveles": valorNivel, "velocidad": velocidad}

# Método para actualizar los puntajes del jugador (CLÁSICO).
func _actualizar_puntajes(path):
	var totalActual = velocidad + precisionActual + valorNivel
	var is_new_record := false
	var diff_key := "easy"  # Este script es SOLO para Easy

	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var puntajes = file.get_var()
		file.close()

		# Asegurar que existan las 3 dificultades y campos nuevos
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

	# Para que Puntaje.gd sepa si hay récord nuevo
	Score.latest_total_score = totalActual
	Score.is_new_best = is_new_record

# Guardado Time Attack por modo + dificultad (sin romper tu formato clásico)
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

# Método para volver a la pantalla de selección de niveles.
func go_selection():
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")

# Crea una flecha entre una imagen y un texto
func crear_flecha(imagen_box: Node2D, texto_box: Node2D) -> void:
	if arrows.has(imagen_box.value):
		return

	var line := Line2D.new()
	line.name = "Arrow_Line_%s" % imagen_box.value
	line.width = 5.0
	line.default_color = Color(0.2, 0.8, 0.2, 0.6)
	line.z_index = 10
	add_child(line)

	arrows[imagen_box.value] = {
		"line": line,
		"imagen": imagen_box,
		"texto": texto_box,
	}

	actualizar_flecha(imagen_box.value)

func actualizar_flecha(value: String) -> void:
	if not arrows.has(value):
		return

	var arrow_data = arrows[value]
	var line: Line2D = arrow_data["line"]
	var imagen_box: Node2D = arrow_data["imagen"]
	var texto_box: Node2D = arrow_data["texto"]

	if not is_instance_valid(line) or not is_instance_valid(imagen_box) or not is_instance_valid(texto_box):
		return

	var fondo: Sprite2D = imagen_box.get_node("Button/Fondo")
	var tabla: Sprite2D = texto_box.get_node("Button/Tabla")

	if not is_instance_valid(fondo) or not is_instance_valid(tabla):
		return

	var start_global: Vector2 = _get_sprite_edge_global(fondo, true)
	var end_global: Vector2 = _get_sprite_edge_global(tabla, false)

	var start_local: Vector2 = to_local(start_global)
	var end_local: Vector2 = to_local(end_global)

	line.clear_points()
	line.add_point(start_local)
	line.add_point(end_local)

func eliminar_todas_las_flechas() -> void:
	for value in arrows.keys():
		var arrow_data = arrows[value]
		if arrow_data is Dictionary and arrow_data.has("line"):
			var line: Line2D = arrow_data["line"]
			if is_instance_valid(line):
				line.queue_free()
	arrows.clear()

func _get_sprite_edge_global(sprite: Sprite2D, right: bool) -> Vector2:
	var center: Vector2 = sprite.global_position

	if sprite.texture:
		var half_width: float = sprite.texture.get_size().x * sprite.scale.x / 2.0
		if right:
			return center + Vector2(half_width, 0.0)
		else:
			return center - Vector2(half_width, 0.0)

	return center
