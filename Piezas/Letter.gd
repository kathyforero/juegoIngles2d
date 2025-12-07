extends Node2D
@export var letter = "A"
var dragging = false
var originalpos = Vector2(10,10)
var snap_to = Vector2(0,0)
var target_letter = "A"
var correct = false
var locked = false  # Bloqueo permanente cuando está correcta y en posición
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
