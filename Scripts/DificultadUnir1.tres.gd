extends Node2D

#Signals
signal update_scene(path)
signal update_title(new_title)
signal set_timer()
signal update_difficulty(new_difficulty)
signal update_level(new_level)
signal set_not_visible_image()

var en: bool = false

func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false   # por defecto español


func update_language_difficulty():
	# Fondo de “Seleccionar dificultad”
	var bg_sprite := $ParallaxBackground/ParallaxLayer/Sprite2D

	if en:
		# Modo INGLÉS
		bg_sprite.texture = load("res://Sprites/global/SelDificultadMatch.png")

		$TextureButton.texture_normal  = load("res://Sprites/buttons/Boton_easy.png")
		$TextureButton.texture_hover   = load("res://Sprites/buttons/boton_easy_hover.png")

		$TextureButton2.texture_normal = load("res://Sprites/buttons/Boton_medium.png")
		$TextureButton2.texture_hover  = load("res://Sprites/buttons/boton_medium_hover.png")
		$TextureButton2.texture_disabled = $TextureButton2.texture_normal

		$TextureButton3.texture_normal = load("res://Sprites/buttons/Boton_difficult.png")
		$TextureButton3.texture_hover  = load("res://Sprites/buttons/Boton_difficult_hover.png")
		$TextureButton3.texture_disabled = $TextureButton3.texture_normal
	else:
		# Modo ESPAÑOL
		bg_sprite.texture = load("res://Sprites/global/SelDificultadMatch_es.png")

		$TextureButton.texture_normal  = load("res://Sprites/buttons/Boton_easy_es.png")
		$TextureButton.texture_hover   = load("res://Sprites/buttons/boton_easy_hover_es.png")

		$TextureButton2.texture_normal = load("res://Sprites/buttons/Boton_medium_es.png")
		$TextureButton2.texture_hover  = load("res://Sprites/buttons/boton_medium_hover_es.png")
		$TextureButton2.texture_disabled = $TextureButton2.texture_normal

		$TextureButton3.texture_normal = load("res://Sprites/buttons/Boton_difficult_es.png")
		$TextureButton3.texture_hover  = load("res://Sprites/buttons/Boton_difficult_hover_es.png")
		$TextureButton3.texture_disabled = $TextureButton3.texture_normal


# Called when the node enters the scene tree for the first time.
func _ready():
	emit_signal("set_timer")
	emit_signal("update_scene", "menu_juegos")
	emit_signal("update_title", "Match it")
	en = load_language_setting()   # lee idioma guardado
	update_language_difficulty()   # aplica texturas según idioma
	#emit_signal("update_difficulty", "Easy")
	#emit_signal("update_level", "1")
	emit_signal("set_not_visible_image")
	$TextureButton2.disabled = true
	$TextureButton3.disabled = true
	verificar_progreso(Global.rutaArchivos+"/Progress/progressMinigames.dat")
	

func actualizar_candados(progreso, minigame):
	if(progreso[minigame]["medium"] && progreso[minigame]["firstMedium"] == false):
		$Sprite2D.visible = false
		$TextureButton2.disabled = false
		$TextureButton2.mouse_default_cursor_shape = $TextureButton2.CURSOR_POINTING_HAND
	if(progreso[minigame]["hard"] && progreso[minigame]["firstHard"] == false):
		$Sprite2D3.visible=false
		$TextureButton3.disabled = false
		$TextureButton3.mouse_default_cursor_shape = $TextureButton3.CURSOR_POINTING_HAND
	
	if(progreso[minigame]["medium"] && progreso[minigame]["firstMedium"]):
		$Sprite2D/AnimationPlayer.play("Unlock")
		await $Sprite2D/AnimationPlayer.animation_finished
		$TextureButton2.disabled = false
		$TextureButton2.mouse_default_cursor_shape = $TextureButton2.CURSOR_POINTING_HAND
		progreso[minigame]["firstMedium"] = false
		actualizar_archivo(progreso, Global.rutaArchivos+"/Progress/progressMinigames.dat")
		
	elif(progreso[minigame]["hard"] && progreso[minigame]["firstHard"]):
		$Sprite2D3/AnimationPlayer.play("Unlock")
		await $Sprite2D3/AnimationPlayer.animation_finished
		$TextureButton3.disabled = false	
		$TextureButton3.mouse_default_cursor_shape = $TextureButton3.CURSOR_POINTING_HAND
		progreso[minigame]["firstHard"] = false
		actualizar_archivo(progreso, Global.rutaArchivos+"/Progress/progressMinigames.dat")
	

		 
func actualizar_archivo(progress, path):
	if DirAccess.remove_absolute(path) == OK:	 
			print("Archivo existente borrado.")
			var new_file = FileAccess.open(path ,FileAccess.WRITE)
			new_file.store_var(progress)
			new_file = null
	else:
			print("Error al intentar borrar el archivo.")

func verificar_progreso(path):
	if FileAccess.file_exists(path):  # Verifica si el archivo existe  
		print("ARCHIVO EXISTE")
		var file = FileAccess.open(path, FileAccess.READ) # Abre el archivo en modo lectura
		var progreso = file.get_var()
		file = null
		actualizar_candados(progreso, "match")
		
		
	else:
		print("ARCHIVO NO EXISTE")
		var content = {
			"puzzle":{
				"easy":true,
				"medium":false,
				"hard":false,
				"firstMedium":false,
				"firstHard":false,				
			},
			"match":{
				"easy":true,
				"medium":false,
				"hard":false,
				"firstMedium":false,
				"firstHard":false,
			},
			"order":{
				"easy":true,
				"medium":false,
				"hard":false,
				"firstMedium":false,
				"firstHard":false,				
			},
		}
		var file = FileAccess.open(path ,FileAccess.WRITE)
		file.store_var(content)
		file = null

func _on_btn_go_back_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_juegos.tscn")


func _on_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/Games/UnirFacil1.tscn")


func _on_texture_button_mouse_entered():
	pass # Replace with function body.


func _on_texture_button_pressed():
	ButtonClick.button_click()
	Score.actualDifficult = Score.difficult["easy"] 
	get_tree().change_scene_to_file("res://Escenas/Games/UnirFacil1.tscn")


func _on_texture_button_2_pressed():
	ButtonClick.button_click()
	Score.actualDifficult = Score.difficult["medium"]
	get_tree().change_scene_to_file("res://Escenas/Games/UnirMedium.tscn")


func _on_texture_button_3_pressed():
	ButtonClick.button_click()
	Score.actualDifficult = Score.difficult["hard"]
	get_tree().change_scene_to_file("res://Escenas/Games/UnirHard.tscn")
