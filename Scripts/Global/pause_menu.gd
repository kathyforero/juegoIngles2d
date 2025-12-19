extends Control

@onready var btn_continuar: Button = $btn_continuar
@onready var btn_menu: Button = $btn_menu

func _ready():
	# El menú ya aparece visible cuando se instancia
	visible = true

	# Este nodo sigue vivo aunque el árbol esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Pausar el juego
	get_tree().paused = true

	# Conectar botones
	btn_continuar.pressed.connect(_on_continuar_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)


func _on_continuar_pressed() -> void:
	# Quitar pausa y destruir el menú
	get_tree().paused = false
	queue_free()


func _on_menu_pressed() -> void:
	# Quitar pausa y volver al menú de juegos
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn") # cambia la ruta si tu menú está en otro lado
