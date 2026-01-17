extends Control

# Señal que se emite para actualizar la escena, en este caso el menú principal.
signal update_scene(path)

var en: bool = false
# Variable para controlar si el modo random está desbloqueado
var random_desbloqueado = false

# Función que se llama cuando el nodo entra en la escena por primera vez.
# Emite una señal para indicar que se debe mostrar el menú principal.

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false   # por defecto español


func update_language_minigames():
	if en:
		# English mode
		$Letrero.texture = load("res://Sprites/mini_games/Letrero_minigame.png")
		$btn_random.text = "RANDOM\nMODE"
		$btn_random.tooltip_text = "Play a random minigame"
		$btn_time_attack.text = "TURBO\nMODE"
		$btn_time_attack.tooltip_text = "Endless rounds until time runs out"
		$btn_practice_on.text = "Free practice mode"
		$btn_practice_off.text = "Normal Mode"
	else:
		# Spanish mode
		$Letrero.texture = load("res://Sprites/mini_games/Letrero_minigame_es.png")
		$btn_random.text = "MODO\nALEATORIO"
		$btn_random.tooltip_text = "Juega un minijuego aleatorio"
		$btn_time_attack.text = "MODO\nTURBO"
		$btn_time_attack.tooltip_text = "Rondas infinitas hasta que se acabe el tiempo."
		$btn_practice_on.text = "Modo práctica Libre"
		$btn_practice_off.text = "Modo normal"


func _ready():
	emit_signal("update_scene", "menu_principal")
	# Deshabilitamos Random y mostramos candado al inicio
	
	en = load_language_setting()          # lee idioma desde el JSON
	update_language_minigames()           # cambia las texturas según idioma
	
	$btn_random.disabled = true
	# NO deshabilitamos el botón, solo mostramos el candado
	# $btn_random.disabled = true
	$btn_random.mouse_default_cursor_shape = Control.CURSOR_ARROW
	$candado.visible = true
	# Conectar señal gui_input para capturar clics incluso cuando disabled
	$btn_random.gui_input.connect(_on_btn_random_gui_input)
	# Conectar señales para cambiar el cursor cuando el mouse está encima
	$btn_random.mouse_entered.connect(_on_btn_random_mouse_entered)
	$btn_random.mouse_exited.connect(_on_btn_random_mouse_exited)
	verificar_progreso(Global.rutaArchivos + "/Progress/progressMinigames.dat")
	apply_practice_ui()

func actualizar_candados(progreso):
	# Solo desbloqueamos Random si se cumplen los requisitos
	if progreso["puzzle"]["hard"] and progreso["match"]["hard"] and progreso["order"]["hard"]:
		random_desbloqueado = true
		
		# Solo reproducir animación si firstUnlock es true
		if $candado.visible and progreso["random"]["firstUnlock"]:
			$candado/AnimationPlayer.play("Unlock")
			await $candado/AnimationPlayer.animation_finished
			$candado.visible = false

			# Marcar como desbloqueado permanentemente
			progreso["random"]["firstUnlock"] = false
			actualizar_archivo(progreso, Global.rutaArchivos + "/Progress/progressMinigames.dat")
		else:
			# Ya fue desbloqueado antes, solo ocultamos candado si sigue visible
			$candado.visible = false

		# Habilitamos el botón y el cursor de mano
		$btn_random.disabled = false
		$btn_random.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	else:
		random_desbloqueado = false


		
func verificar_progreso(path):
	if FileAccess.file_exists(path):  
		print("ARCHIVO EXISTE")
		var file = FileAccess.open(path, FileAccess.READ) 
		var progreso = file.get_var()
		file = null
		# Inicializar random si no existe
		if not progreso.has("random"):
			progreso["random"] = {"firstUnlock": true}
		actualizar_candados(progreso)
	else:
		print("ARCHIVO NO EXISTE")
		var content = {
			"puzzle": {
				"easy": true,
				"medium": false,
				"hard": false,
				"firstMedium": false,
				"firstHard": false
			},
			"match": {
				"easy": true,
				"medium": false,
				"hard": false,
				"firstMedium": false,
				"firstHard": false
			},
			"order": {
				"easy": true,
				"medium": false,
				"hard": false,
				"firstMedium": false,
				"firstHard": false
			},
			"random": {
				"firstUnlock": true
			}
		}
		var file = FileAccess.open(path ,FileAccess.WRITE)
		file.store_var(content)
		file = null
		actualizar_candados(content)
		
func actualizar_archivo(progress, path):
	var file = FileAccess.open(path ,FileAccess.WRITE)
	file.store_var(progress)
	file.close()

# Función que se ejecuta cuando el botón del juego de puzzles es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de Puzzles.
func _on_btn_puzzle_pressed():
	if not Score.is_practice():
		Score.set_mode_classic()
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/Dificultad_Puzzle.tscn")

# Función que se ejecuta cuando el botón del juego 'Match It' es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de 'Match It'.
func _on_btn_match_pressed():
	if not Score.is_practice():
		Score.set_mode_classic()
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/Dificultad_MatchIt.tscn")

# Función que se ejecuta cuando el botón del juego 'Order It' es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de 'Order It'.
func _on_btn_order_pressed():
	if not Score.is_practice():
		Score.set_mode_classic()
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/Dificultad_OrderIt.tscn")

# Función que se ejecuta cuando se hace clic en el botón random (incluso si está deshabilitado)
func _on_btn_random_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not random_desbloqueado:
			var texto = _get_random_locked_modal()
			$ModalBloqueo.mostrar_modal(texto.title, texto.message)

# Función que se ejecuta cuando el mouse entra sobre el botón random
func _on_btn_random_mouse_entered():
	$btn_random.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# Función que se ejecuta cuando el mouse sale del botón random
func _on_btn_random_mouse_exited():
	if not random_desbloqueado:
		$btn_random.mouse_default_cursor_shape = Control.CURSOR_ARROW
	else:
		$btn_random.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

# Función que se ejecuta cuando el botón del modo random es presionado.
func _on_btn_random_pressed():
	if not random_desbloqueado:
		return

	# Random debe comportarse como Classic (y no heredar Time Attack)
	if not Score.is_practice():
		Score.set_mode_classic()

	Score.reset_run_state()

	ButtonClick.button_click()
	DificultadRandom.load_next_random_level()

func _get_random_locked_modal() -> Dictionary:
	if en:
		return {
			"title": "Random Mode Locked!",
			"message": "Complete every HARD level of Puzzle, Match It and Order It to unlock this mode."
		}
	return {
		"title": "Modo Random Bloqueado!",
		"message": "Termina todos los niveles difíciles para desbloquear Random.\n\n¡Sigue practicando!"
	}


func _on_btn_time_attack_pressed():
	ButtonClick.button_click()
	Score.reset_run_state()
	get_tree().change_scene_to_file("res://Escenas/TimeAttackConfig.tscn")

func _on_btn_practice_on_pressed():
	ButtonClick.button_click()
	Score.set_mode_practice(Score.actualDifficult)
	apply_practice_ui()

func _on_btn_practice_off_pressed():
	ButtonClick.button_click()
	if Score.is_practice():
		Score.set_mode_classic()
	apply_practice_ui()

func apply_practice_ui():
	var practice_on := Score.is_practice()
	$btn_practice_on.visible = not practice_on
	$btn_practice_off.visible = practice_on
	$btn_random.visible = not practice_on
	$btn_time_attack.visible = not practice_on
	$candado.visible = (not practice_on) and (not random_desbloqueado)
