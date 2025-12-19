extends Control

# Señal que se emite para actualizar la escena, en este caso el menú principal.
signal update_scene(path)

var en: bool = false
# Variable para controlar si el modo random está desbloqueado
var random_desbloqueado = false

@onready var btn_random       = $btn_random      # botón de modo random
@onready var candado          = $candado         # sprite de candado
@onready var btn_practice_on  = $btn_practice_on # activar práctica
@onready var btn_practice_off = $btn_practice_off # volver a modo normal

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
		# Modo inglés
		$Letrero.texture = load("res://Sprites/mini_games/Letrero_minigame.png")
		$btn_random/Sprite2D.texture = load("res://Sprites/mini_games/Letrero_Random.png")
		btn_practice_on.text = "Free Practice Mode"
		btn_practice_off.text = "Normal Mode"
	else:
		# Modo español
		$Letrero.texture = load("res://Sprites/mini_games/Letrero_minigame_es.png")
		$btn_random/Sprite2D.texture = load("res://Sprites/mini_games/Letrero_Random_es.png")
		btn_practice_on.text = "Modo Práctica Libre"
		btn_practice_off.text = "Modo Normal"

func _ready():
	emit_signal("update_scene", "menu_principal")
	# Deshabilitamos Random y mostramos candado al inicio
	
	btn_practice_on.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_practice_off.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	en = load_language_setting()          # lee idioma desde el JSON
	update_language_minigames()           # cambia las texturas según idioma
	
	# Siempre arrancamos en modo NORMAL
	Score.practice_mode = false
	
	# Estado inicial de los botones de práctica
	btn_practice_on.visible = true
	btn_practice_off.visible = false
	
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
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadOracion1.tscn")

# Función que se ejecuta cuando el botón del juego 'Match It' es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de 'Match It'.
func _on_btn_match_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadUnir1.tscn")

# Función que se ejecuta cuando el botón del juego 'Order It' es presionado.
# Reproduce el sonido de clic y cambia la escena al nivel de dificultad de 'Order It'.
func _on_btn_order_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/DificultadPalabra1.tscn")

# Función que se ejecuta cuando se hace clic en el botón random (incluso si está deshabilitado)
func _on_btn_random_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not random_desbloqueado:
			var titulo = "¡Modo Random Bloqueado!"
			var mensaje = "Completa todos los niveles DIFÍCILES de los tres juegos para desbloquearlo."
			$ModalBloqueo.mostrar_modal(titulo, mensaje)

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
	if random_desbloqueado:
		ButtonClick.button_click()
		DificultadRandom.load_next_random_level()


func _on_btn_practice_on_pressed():
	ButtonClick.button_click()

	Score.practice_mode = true

	# En modo práctica NO se muestra Random ni su candado
	btn_random.visible = false
	candado.visible = false

	# Cambiamos la UI de los botones de modo
	btn_practice_on.visible = false
	btn_practice_off.visible = true


func _on_btn_practice_off_pressed():
	ButtonClick.button_click()

	Score.practice_mode = false

	# Volvemos a mostrar Random y candado;
	# verificar_progreso decide si está bloqueado o no.
	btn_random.visible = true
	candado.visible = true

	btn_practice_on.visible = true
	btn_practice_off.visible = false

	verificar_progreso(Global.rutaArchivos + "/Progress/progressMinigames.dat")
