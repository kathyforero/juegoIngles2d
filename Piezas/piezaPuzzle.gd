extends Node2D

@export var letter = "A" 
var dragging = false
var originalpos = Vector2()  # Inicializado en _ready()
var snap_to = Vector2()  # Inicializado en _ready()
var target_letter = "A"
var correct = false
var locked := false

# Doble clic
var last_click_time := 0.0
var double_click_threshold := 0.4
var _auto_place_in_progress := false

func _ready():
	# Establece la posición inicial y el texto del Label
	originalpos = global_position
	snap_to = Vector2()  # Por defecto, no hay una posición de ajuste
	_actualizar_label()

	# Verifica la existencia del padre y abuelo antes de conectar la señal
	var parent = get_parent()
	if parent and parent.get_parent():
		var abuelo = parent.get_parent()
		if abuelo.has_signal("update_phrase"):
			abuelo.connect("update_phrase", Callable(self, "_on_update_phrase"))
		else:
			print("Advertencia: El abuelo no tiene la señal 'update_phrase'.")
	else:
		print("Advertencia: Nodo padre o abuelo no encontrado.")

func _process(_delta):
	# Solo actualiza la posición si se está arrastrando
	if dragging:
		position = get_global_mouse_position()
		correct = false
		$AnimationPlayer.play("RESET")

func _get_drag_data(_at_position):
	print("Iniciando arrastre.")

func _on_button_button_down():
	if locked or correct:
		return

	var now := Time.get_ticks_msec() / 1000.0
	if now - last_click_time < double_click_threshold:
		last_click_time = 0.0
		_auto_place_in_progress = true
		await _posicionar_automaticamente()
		_auto_place_in_progress = false
		return
	last_click_time = now

	dragging = true
	self.move_to_front()

func _on_button_button_up():
	dragging = false

	if _auto_place_in_progress:
		return

	if locked or correct:
		return

	if position.distance_to(snap_to) < 70:
		position = snap_to
		if letter == target_letter:
			await _marcar_correcto()
		else:
			await _marcar_incorrecto()
	else:
		_reset_position()

func _posicionar_automaticamente() -> void:
	if locked or correct:
		return

	var scene := get_tree().current_scene
	if scene == null:
		return

	var ordenada := scene.get_node_or_null("Ordenada")
	if ordenada == null:
		return

	# --- Solo tomar los piezaBox reales (evita sprites/labels decorativos) ---
	var pieza_boxes: Array = []
	for child in ordenada.get_children():
		# Solo los que tienen 'occupied' y 'letter' (piezaBox.gd)
		if child.get("occupied") == null:
			continue
		if child.get("letter") == null:
			continue
		pieza_boxes.append(child)

	# Orden izquierda -> derecha (más seguro con global en tu proyecto)
	pieza_boxes.sort_custom(func(a, b): return a.global_position.x < b.global_position.x)

	for box in pieza_boxes:
		if box.occupied:
			continue

		var area: Area2D = $Area2D
		if area == null:
			return

		# OJO: tu script usa get_global_mouse_position() pero lo asigna a position,
		# así que es más consistente usar global_position aquí.
		position = box.global_position
		snap_to = box.global_position
		target_letter = box.letter

		# Marcar box como ocupado SIN depender de señales (y sin chocar con coords)
		box.occupied = true
		box.current_node = area

		if letter == target_letter:
			await _marcar_correcto()
			locked = true
		else:
			await _marcar_incorrecto()
			locked = false

			# liberar box (porque no quedó)
			box.occupied = false
			box.current_node = null
			_reset_position()

		return


func _on_update_phrase():
	originalpos = global_position
	_actualizar_label()

# Función para marcar como correcto
func _marcar_correcto():
	$AnimationPlayer.play("Correcto")
	await $AnimationPlayer.animation_finished
	correct = true
	locked = true

# Función para manejar cuando es incorrecto
func _marcar_incorrecto(): 
	var principal = get_parent().get_parent()
	if principal:
		if principal.has_method("_flash_hint_button_error"):
			principal._flash_hint_button_error()
		if principal.precisionActual > principal.precisionMinima:
			principal.precisionActual -= 10
		print("Precision ahora: ", principal.precisionActual)
	$AnimationPlayer.play("Incorrecto")
	await $AnimationPlayer.animation_finished
	_reset_position()


# Función para reiniciar la posición
func _reset_position():
	position = originalpos
	correct = false
	locked = false
	$AnimationPlayer.play("Retorno")

# Función para actualizar el texto del Label
func _actualizar_label():
	var label = $"InteractivoLetra(vacio)/Label"
	if label:
		label.text = letter
	else:
		print("Advertencia: Nodo Label no encontrado.")

# Funciones auxiliares para animaciones
func _animacion_pista():
	$AnimationPlayer.play("Pista")

func _animacion_finalizado():
	$AnimationPlayer.play("Final")
	await $AnimationPlayer.animation_finished

func _animacion_retorno():
	$AnimationPlayer.play("Retorno")

func _reiniciar_variables():
	originalpos = global_position
	snap_to = Vector2()
	correct = false
	locked = false
	last_click_time = 0.0
	_actualizar_label()
