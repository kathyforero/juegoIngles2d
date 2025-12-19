extends Node2D

# Valor asociado con la imagen para el emparejamiento.
var value = "a"  

# Referencias a nodos en la escena.
@onready var fondo_clic = $Button/Fondo_clic
var blocked = false  # Indica si la imagen está bloqueada (ya emparejada).
@onready var imagen = $Button/imagen
@onready var animation_image = $AnimationImage

func _ready():
	# Inicializar la visibilidad del fondo de clic.
	fondo_clic.visible = false

# Función para colocar una imagen en el nodo y asignarle un valor.
func put_image(url_path, entry_value):
	imagen.texture = load(url_path)  # Cargar la textura de la imagen desde la ruta proporcionada.
	value = entry_value  # Asignar el valor asociado con la imagen.
	
# Método que se ejecuta cuando se presiona el botón asociado a la imagen.
func _on_button_pressed():
	# Si ya está emparejada, no hacer nada
	if blocked:
		return

	var parent = get_parent()

	# Si el juego está en pausa de interacción (mostrando ✔ / ✖), ignorar el clic
	if "interaction_locked" in parent and parent.interaction_locked:
		return

	# Solo si NO estamos bloqueados, mostrar selección y avisar al juego
	fondo_clic.visible = true
	parent.handle_value_selected(self)

	
# Animación que se ejecuta cuando se logra un emparejamiento correcto.
func animation_match():
	animation_image.play("Match")  # Reproducir la animación de emparejamiento correcto.

# Animación que se ejecuta cuando el emparejamiento falla.
func animation_no_match():
	animation_image.play("No_match")  # Reproducir la animación de error.

# Animación que se ejecuta cuando se proporciona una pista.
func animation_pista():
	animation_image.play("Pista")  # Reproducir la animación de pista.

# Animación para reiniciar el estado del componente.
func animation_reset():
	blocked = false  # Desbloquear la imagen.
	animation_image.play("RESET")  # Reproducir la animación de reinicio.
