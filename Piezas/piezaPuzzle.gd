extends Node2D

@export var letter = "A" 
var dragging = false
var originalpos = Vector2()  # Inicializado en _ready()
var snap_to = Vector2()  # Inicializado en _ready()
var target_letter = "A"
var correct = false
var locked = false  # Bloqueo permanente cuando está correcta y en posición

# Variables para doble clic
var last_click_time = 0.0
var double_click_threshold = 0.4  # Tiempo máximo entre clics para considerar doble clic

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
	# Solo actualiza la posición si se está arrastrando y NO está bloqueada
	if dragging and not locked:
		position = get_global_mouse_position()
		$AnimationPlayer.play("RESET")

func _get_drag_data(_at_position):
	print("Iniciando arrastre.")

func _on_button_button_down():
	# Si está bloqueada (correcta y en posición), solo reproducir animación
	if locked:
		$AnimationPlayer.play("Correcto")
		return
	
	# Si está correcta pero aún no bloqueada, no permitir arrastrar
	if correct:
		return
	
	# Detectar doble clic
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_click_time < double_click_threshold:
		# Es un doble clic, posicionar automáticamente
		_posicionar_automaticamente()
		last_click_time = 0.0  # Resetear para evitar triple clic
		return
	
	last_click_time = current_time
		
	dragging = true
	self.move_to_front()

func _on_button_button_up():
	# Si está bloqueada, no hacer nada
	if locked or correct:
		dragging = false
		return
		
	dragging = false
	if position.distance_to(snap_to) < 70:  # Verifica si está cerca del objetivo
		position = snap_to
		if letter == target_letter:
			_marcar_correcto()
		else:
			_marcar_incorrecto()
	else:
		_reset_position()

func _on_update_phrase():
	originalpos = global_position
	_actualizar_label()

# Función para marcar como correcto
func _marcar_correcto():
	correct = true
	$AnimationPlayer.play("Correcto")
	await $AnimationPlayer.animation_finished
	# Asegurarse de que el scale regrese a normal después de la animación
	$"InteractivoLetra(vacio)".scale = Vector2(1, 1)
	# Bloquear permanentemente la pieza en su posición
	locked = true

# Función para manejar cuando es incorrecto
func _marcar_incorrecto(): 
	var principal = get_parent().get_parent()
	if principal and principal.has_method("precisionActual"):
		if principal.precisionActual > principal.precisionMinima:
			principal.precisionActual -= 10
	$AnimationPlayer.play("Incorrecto")
	await $AnimationPlayer.animation_finished
	_reset_position()

# Función para reiniciar la posición
func _reset_position():
	position = originalpos
	correct = false
	# Asegurarse de resetear el scale cuando se devuelve
	$"InteractivoLetra(vacio)".scale = Vector2(1, 1)
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
	# Asegurarse de que la pieza esté en verde (si ya está locked, ya está en verde)
	# Esperar un momento para que se vea el verde antes de cambiar a azul
	if locked:
		await get_tree().create_timer(0.2).timeout
	
	# Reproducir la animación Final (verde a azul)
	$AnimationPlayer.play("Final")
	await $AnimationPlayer.animation_finished
	# Pequeño delay adicional para asegurar que se vea completamente la iluminación verde
	await get_tree().create_timer(0.1).timeout

func _animacion_retorno():
	$AnimationPlayer.play("Retorno")
	await $AnimationPlayer.animation_finished

func _reiniciar_variables():
	originalpos = global_position
	snap_to = Vector2()
	correct = false
	locked = false
	dragging = false
	# Asegurarse de resetear el scale y color
	$"InteractivoLetra(vacio)".scale = Vector2(1, 1)
	$"InteractivoLetra(vacio)".modulate = Color(1, 1, 1, 1)
	$AnimationPlayer.play("RESET")
	_actualizar_label()

# Función para posicionar automáticamente la pieza en el primer espacio disponible
func _posicionar_automaticamente():
	if locked or correct:
		return
	
	# Buscar el nodo padre que contiene los piezaBox (FrasesNivel1, FrasesNivel2, FrasesNivel3)
	var parent_scene = get_tree().current_scene
	if not parent_scene:
		return
	
	# Buscar el nodo "Ordenada" que contiene los piezaBox
	var ordenada_node = parent_scene.get_node_or_null("Ordenada")
	if not ordenada_node:
		return
	
	# Buscar el PRIMER piezaBox disponible (de izquierda a derecha), sin importar la letra
	var pieza_boxes = ordenada_node.get_children()
	# Ordenar los piezaBox por posición X para ir de izquierda a derecha
	pieza_boxes.sort_custom(func(a, b): return a.position.x < b.position.x)
	
	for pieza_box in pieza_boxes:
		# Verificar que es un piezaBox accediendo directamente a sus propiedades
		# Si no tiene las propiedades, simplemente continuar con el siguiente
		if not pieza_box.has_method("_animacion_pista"):
			continue
		
		# Buscar el PRIMER espacio disponible (sin importar qué letra debería ir ahí)
		if not pieza_box.occupied:
			# Obtener el Area2D de esta pieza
			var area = $Area2D
			if not area:
				return
			
			# Posicionar la pieza automáticamente
			position = pieza_box.position
			snap_to = pieza_box.position
			target_letter = pieza_box.letter
			
			# Activar el piezaBox simulando que la pieza entró al área
			pieza_box._on_area_2d_area_shape_entered(0, area, 0, 0)
			
			# Verificar si es correcta y marcarla
			if letter == target_letter:
				_marcar_correcto()
			else:
				# Si no es correcta, reproducir animación incorrecta y devolver
				_marcar_incorrecto()
			
			return
	
	# Si no se encontró un espacio disponible, reproducir animación de error sutil
	_animacion_pista()
