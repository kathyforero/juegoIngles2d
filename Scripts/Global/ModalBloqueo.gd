extends Control

var en: bool = false

func _ready():
	en = load_language_setting()
	_update_button_label()

func mostrar_modal(titulo: String, mensaje: String):
	en = load_language_setting()
	_update_button_label()
	$LabelTitulo.text = titulo
	$LabelMensaje.text = mensaje
	visible = true
	ButtonClick.button_click()

func _on_button_cerrar_pressed():
	ButtonClick.button_click()
	visible = false

func _on_color_rect_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		visible = false

func _update_button_label():
	if en:
		$LabelBoton.text = "OK"
	else:
		$LabelBoton.text = "Entendido"

func load_language_setting() -> bool:
	if FileAccess.file_exists("user://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("user://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false
