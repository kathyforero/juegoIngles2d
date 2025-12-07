extends Node2D
@export var letter = "A"
var dragging = false
var originalpos = Vector2(10,10)
var snap_to = Vector2(0,0)
var target_letter = "A"
var correct = false
var locked = false  # Bloqueo permanente cuando está correcta y en posición

# Variables para doble clic
var last_click_time = 0.0
var double_click_threshold = 0.4  # Tiempo máximo entre clics para considerar doble clic

# Called when the node enters the scene tree for the first time.
func _ready():
	originalpos = global_position
	pass

func setLetter(letra):
	letter=letra
	$"InteractivoLetra(vacio)/Label".text = letra
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# Solo actualiza la posición si se está arrastrando y NO está bloqueada
	if dragging and not locked:
		position = get_global_mouse_position()
		correct = false
		$AnimationPlayer.play("RESET")
	pass

func _get_drag_data(_at_position):
	print("arrastando")

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
	pass 

func _on_button_button_up():
	# Si está bloqueada, no hacer nada
	if locked or correct:
		dragging = false
		return
		
	dragging = false
	if position.distance_to(snap_to)<45:
		position = snap_to
		if letter == target_letter:
			_marcar_correcto()
		else:
			$AnimationPlayer.play("Incorrecto")
			await $AnimationPlayer.animation_finished
			position = originalpos
			correct = false
			if(Score.perfectBonus>20):
				Score.perfectBonus-=10
	else:
		position = originalpos
	
	pass

# Función para marcar como correcto
func _marcar_correcto():
	correct = true
	$AnimationPlayer.play("Correcto")
	await $AnimationPlayer.animation_finished
	# Asegurarse de que el scale regrese a normal después de la animación
	$"InteractivoLetra(vacio)".scale = Vector2(1, 1)
	# Bloquear permanentemente la letra en su posición
	locked = true 

func hint():
	$AnimationPlayer.play("Hint")

func animacionFinalizado():
	$AnimationPlayer.play("RESET")
	await $AnimationPlayer.animation_finished
	$AnimationPlayer.play("newRound")
	await $AnimationPlayer.animation_finished

func resetVars():
	dragging = false
	snap_to = Vector2(0,0)
	correct = false
	locked = false
	
func resetPos():
	position=originalpos
	# Asegurarse de resetear el scale cuando se devuelve
	$"InteractivoLetra(vacio)".scale = Vector2(1, 1)
	$AnimationPlayer.play("RESET")

# Función para posicionar automáticamente la letra en el siguiente espacio disponible
func _posicionar_automaticamente():
	if locked or correct:
		return
	
	# Buscar el nodo padre que contiene los Letterboxes (OrderEasy, OrderMedium, OrderHard)
	var parent_scene = get_tree().current_scene
	if not parent_scene:
		return
	
	# Buscar el nodo "Ordenada" que contiene los Letterboxes
	var ordenada_node = parent_scene.get_node_or_null("Ordenada")
	if not ordenada_node:
		return
	
	# Buscar el PRIMER Letterbox disponible (de izquierda a derecha), sin importar la letra
	var letterboxes = ordenada_node.get_children()
	# Ordenar los letterboxes por posición X para ir de izquierda a derecha
	letterboxes.sort_custom(func(a, b): return a.position.x < b.position.x)
	
	for letterbox in letterboxes:
		# Verificar que es un Letterbox accediendo directamente a sus propiedades
		# Si no tiene las propiedades, simplemente continuar con el siguiente
		if not letterbox.has_method("setLetter"):
			continue
		
		# Buscar el PRIMER espacio disponible (sin importar qué letra debería ir ahí)
		if not letterbox.occupied:
				# Obtener el Area2D de esta letra
				var area = $Area2D
				if not area:
					return
				
				# Posicionar la letra automáticamente
				position = letterbox.position
				snap_to = letterbox.position
				target_letter = letterbox.letter
				
				# Activar el Letterbox simulando que la letra entró al área
				letterbox._on_area_2d_area_shape_entered(0, area, 0, 0)
				
				# Verificar si es correcta y marcarla
				if letter == target_letter:
					_marcar_correcto()
				else:
					# Si no es correcta, reproducir animación incorrecta y devolver
					$AnimationPlayer.play("Incorrecto")
					await $AnimationPlayer.animation_finished
					position = originalpos
					correct = false
					# Liberar el letterbox
					letterbox._on_area_2d_area_exited(area)
					if(Score.perfectBonus>20):
						Score.perfectBonus-=10
				
				return
	
	# Si no se encontró un espacio disponible, reproducir animación de error sutil
	$AnimationPlayer.play("Hint")
