extends Control

# Señal que se emite para actualizar la escena, necesaria para el botón de regresar.
signal update_scene(path)

# Función que se llama cuando el nodo entra en la escena por primera vez.
# Emite una señal para indicar la escena anterior (para el botón de regresar).
func _ready():
	emit_signal("update_scene", "menu_principal")

