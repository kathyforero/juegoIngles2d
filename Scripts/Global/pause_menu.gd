extends Control

@onready var label: Label = $Label
@onready var btn_continuar: Button = $btn_continuar
@onready var btn_menu: Button = $btn_menu

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("user://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("user://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false
	
func _ready():
	btn_continuar.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn_menu.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	en = load_language_setting()
	
	if en:
		btn_continuar.text = "Continue"
		btn_menu.text = "Return to Menu"
		label.text = "P A U S E D"
	else:
		btn_continuar.text = "Continuar"
		btn_menu.text = "Volver al Menú"
		label.text = "P A U S A D O"
	
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
