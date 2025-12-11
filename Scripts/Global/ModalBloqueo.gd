extends Control

func mostrar_modal(titulo: String, mensaje: String):
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
