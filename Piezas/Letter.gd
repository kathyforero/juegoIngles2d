extends Node2D
@export var letter = "A"
var dragging = false
var originalpos = Vector2(10,10)
var snap_to = Vector2(0,0)
var target_letter = "A"
var correct = false
var locked := false

# Doble clic
var last_click_time := 0.0
var double_click_threshold := 0.4
var _auto_place_in_progress := false

# Called when the node enters the scene tree for the first time.
func _ready():
	originalpos = global_position
	pass

func setLetter(letra):
	letter=letra
	$"InteractivoLetra(vacio)/Label".text = letra
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if dragging:
		position = get_global_mouse_position()
		correct = false
		$AnimationPlayer.play("RESET")
	pass

func _get_drag_data(_at_position):
	print("arrastando")

func _on_button_button_down():
	# Si ya está correcta, no la vuelvas a mover (modo “no la dañes, bro”)
	if locked or correct:
		return

	# Detectar doble clic
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

	if position.distance_to(snap_to) < 45:
		position = snap_to
		if letter == target_letter:
			$AnimationPlayer.play("Correcto")
			correct = true
			locked = true
		else:
			$AnimationPlayer.play("Incorrecto")
			await $AnimationPlayer.animation_finished
			position = originalpos
			correct = false
			locked = false
			if Score.perfectBonus > 20:
				Score.perfectBonus -= 10
				var scene := get_tree().current_scene
				if scene and scene.has_method("_ta_update_live_score"):
					scene._ta_update_live_score()
	else:
		position = originalpos

func _posicionar_automaticamente() -> void:
	if locked or correct:
		return

	var scene := get_tree().current_scene
	if scene == null:
		return

	var ordenada := scene.get_node_or_null("Ordenada")
	if ordenada == null:
		return

	var boxes := ordenada.get_children()
	boxes.sort_custom(func(a, b): return a.position.x < b.position.x)

	for box in boxes:
		# “primer espacio vacío” de izquierda a derecha
		if box.occupied:
			continue

		var area: Area2D = $Area2D
		if area == null:
			return

		# Usamos global_position porque el drag se hace con get_global_mouse_position()
		position = box.global_position
		snap_to = box.global_position
		target_letter = box.letter

		# Marcar ocupado como si hubiera entrado el Area2D
		if box.has_method("_on_area_2d_area_shape_entered"):
			box._on_area_2d_area_shape_entered(RID(), area, 0, 0)

		# Validar si quedó bien
		if letter == target_letter:
			$AnimationPlayer.play("Correcto")
			correct = true
			locked = true
		else:
			$AnimationPlayer.play("Incorrecto")
			await $AnimationPlayer.animation_finished
			position = originalpos
			correct = false
			locked = false

			# Liberar el box
			if box.has_method("_on_area_2d_area_exited"):
				box._on_area_2d_area_exited(area)

			# Penalización (igual que en tu drop normal)
			if Score.perfectBonus > 20:
				Score.perfectBonus -= 10
				var sc := get_tree().current_scene
				if sc and sc.has_method("_ta_update_live_score"):
					sc._ta_update_live_score()
		return


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
	last_click_time = 0.0
	
func resetPos():
	position=originalpos
	$AnimationPlayer.play("RESET")
