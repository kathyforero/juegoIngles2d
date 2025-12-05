extends Control

# Referencia al nodo VideoStreamPlayer que reproduce el video en la interfaz de instrucciones.
@onready var video_stream_player = $TextureRect/Panel/VideoStreamPlayer

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false

func update_language_instructions():
	var scene_name := name
	# Cambiar fondo y texto del botón según idioma
	if en:
		$TextureRect/Button.text = "START"
		match scene_name:
			"InstruccionesFrases":
				$TextureRect/RichTextLabel.text = "Welcome to the puzzle adventure kids!"
			"InstruccionesPalabra":
				$TextureRect/RichTextLabel.text = "Welcome to the order it adventure kids!"
			"InstruccionesUnir":
				$TextureRect/RichTextLabel.text = "Welcome to the match it adventure kids!"
			_:
				$TextureRect/RichTextLabel.text = ""
	else:
		$TextureRect/Button.text = "EMPEZAR"
		match scene_name:
			"InstruccionesFrases":
				$TextureRect/RichTextLabel.text = "¡Bienvenidos a la aventura de puzzle, niños!"
			"InstruccionesPalabra":
				$TextureRect/RichTextLabel.text = "¡Bienvenidos a la aventura de order it, niños!"
			"InstruccionesUnir":
				$TextureRect/RichTextLabel.text = "¡Bienvenidos a la aventura de match it, niños!"
			_:
				$TextureRect/RichTextLabel.text = ""

# Función que reanuda el juego.
# Despausa el árbol de nodos (lo que reactiva el juego) y reproduce la animación de "blur" en reversa para quitar el efecto de desenfoque.
# Después, elimina esta escena de instrucciones.
func resume():
	get_tree().paused = false  # Reactivar el juego.
	$AnimationPlayer.play_backwards("blur")  # Quitar el efecto de desenfoque.
	self.queue_free()  # Eliminar la escena de instrucciones de la pantalla.

# Función que pausa el juego.
# Pausa el árbol de nodos (deteniendo todas las operaciones) y activa la animación de desenfoque en la pantalla.
func pause():
	get_tree().paused = true  # Pausar el juego.
	$AnimationPlayer.play("blur")  # Aplicar el efecto de desenfoque.

# Función que se llama cuando el nodo entra en la escena por primera vez.
# Inicia la animación de "RESET", pausa el juego y comienza la reproducción del video.
func _ready():
	$AnimationPlayer.play("RESET")  # Reiniciar la animación.
	pause()  # Pausar el juego para que se enfoque en las instrucciones.
	en = load_language_setting()
	update_language_instructions()
	video_stream_player.play()  # Reproducir el video de instrucciones.

# Función que se ejecuta cuando el botón es presionado.
# Detiene el video y reanuda el juego cuando el jugador ha terminado de ver las instrucciones.
func _on_button_pressed():
	ButtonClick.button_click()  # Efecto de clic del botón.
	video_stream_player.stop()  # Detener el video de instrucciones.
	resume()  # Reanudar el juego y eliminar la escena de instrucciones.
