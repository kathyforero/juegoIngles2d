extends Node2D
#@onready var barraVelocidad = $BarraVelocidad
#@onready var barraPrecision = $BarraPrecision
#@onready var barraNiveles = $BarraNiveles
var velocidad = 0
var precision = 0
var niveles = 0
var maximoVelocidad = 300
var maximoPrecision = 300
var maximoNiveles = 300
var maximoScaleX = 0.256
enum ventana {PUZZLE = 0, MATCH = 1, ORDER = 2}
var ventanaActual = ventana.PUZZLE
var posActual = 0
var ejecutablePath = Global.rutaArchivos
# Called when the node enters the scene tree for the first time.
func _ready():
	$RetrocederButton.visible = false
	#Leer archivo
	_leer_archivo()	
	_actualizar_valores()	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func _leer_archivo():
	match ventanaActual:
		0:
			$Label4.text= "Puzzle's Best Scores"
			_cargar_puntajes(ejecutablePath+"/Scores/puntajesPuzzle.dat")
		1:
			$Label4.text= "Match It's Best Scores"
			_cargar_puntajes(ejecutablePath+"/Scores/puntajesMatch.dat")
		2:
			$Label4.text= "Order It's Best Scores"
			_cargar_puntajes(ejecutablePath+"/Scores/puntajesOrder.dat")

func _get_total_from_dict(puntajes: Dictionary, diff: String) -> int:
	if not puntajes.has(diff):
		return 0
	var d = puntajes[diff]
	if d.has("best_score"):
		return int(d["best_score"])
	var v = int(d.get("velocidad", 0))
	var p = int(d.get("precision", 0))
	var n = int(d.get("niveles", 0))
	return v + p + n

func _cargar_puntajes(path: String) -> void:
	if not FileAccess.file_exists(path):
		# No hay datos, pones valores por defecto
		$EasyScoreLabel.text = "0"
		$EasyNameLabel.text = "---"
		$MediumScoreLabel.text = "0"
		$MediumNameLabel.text = "---"
		$HardScoreLabel.text = "0"
		$HardNameLabel.text = "---"
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var puntajes = file.get_var()
	file.close()

	# EASY
	var easy_dict  = puntajes.get("easy", {})
	var easy_score = int(easy_dict.get("best_score", 0))
	var easy_name  = str(easy_dict.get("name", "---"))

	# MEDIUM
	var med_dict   = puntajes.get("medium", {})
	var med_score  = int(med_dict.get("best_score", 0))
	var med_name   = str(med_dict.get("name", "---"))

	# HARD
	var hard_dict  = puntajes.get("hard", {})
	var hard_score = int(hard_dict.get("best_score", 0))
	var hard_name  = str(hard_dict.get("name", "---"))

	$EasyScoreLabel.text   = str(easy_score)
	$EasyNameLabel.text    = easy_name
	$MediumScoreLabel.text = str(med_score)
	$MediumNameLabel.text  = med_name
	$HardScoreLabel.text   = str(hard_score)
	$HardNameLabel.text    = hard_name

func _actualizar_valores():
	#var posVelInicio = barraVelocidad.position.x - (barraVelocidad.scale.x * barraVelocidad.texture.get_size().x * 0.5)
	#barraVelocidad.scale.x = (float(velocidad)/float(maximoVelocidad)) * float(maximoScaleX)
	#var posVelDespues = posVelInicio + (barraVelocidad.scale.x * barraVelocidad.texture.get_size().x * 0.5)
	#barraVelocidad.position.x = posVelDespues
	#
	#var posPInicio = barraPrecision.position.x - (barraPrecision.scale.x * barraPrecision.texture.get_size().x * 0.5)
	#barraPrecision.scale.x = (float(precision)/float(maximoPrecision)) * float(maximoScaleX)
	#var posPDespues = posPInicio + (barraPrecision.scale.x * barraPrecision.texture.get_size().x * 0.5)
	#barraPrecision.position.x = posPDespues
	#
	#var posNInicio = barraNiveles.position.x - (barraNiveles.scale.x * barraNiveles.texture.get_size().x * 0.5)
	#barraNiveles.scale.x = (float(niveles)/float(maximoNiveles)) * float(maximoScaleX)
	#var posNDespues = posNInicio + (barraNiveles.scale.x * barraNiveles.texture.get_size().x * 0.5)
	#barraNiveles.position.x = posNDespues
	
	#var velocidadP = (float(velocidad)/float(maximoVelocidad))*100
	#var precisionP =  (float(precision)/float(maximoPrecision))*100
	#var nivelesP =   (float(niveles)/float(maximoNiveles))*100
	#print(str(velocidadP))
	#$VelocidadPuntaje.text = str(int(velocidadP))+"%"
	#$PrecisionPuntaje.text = str(int(precisionP))+"%"
	#$NivelesPuntaje.text = str(int(nivelesP))+"%"
	#$PuntajeTotal.text = str(int((velocidadP+precisionP+nivelesP)/3))+"%"
	match ventanaActual:
		ventana.PUZZLE:
			$MinijuegoNombre.text = "Puzzle"
		ventana.MATCH:
			$MinijuegoNombre.text = "Match it"
		ventana.ORDER:
			$MinijuegoNombre.text = "Order it"

# Replace with function body.
func _on_siguiente_button_pressed():
	ButtonClick.button_click()
	ventanaActual += 1
	if(ventanaActual == ventana.ORDER):
		$SiguienteButton.visible = false
	if(ventanaActual > 0):
		$RetrocederButton.visible = true
	_leer_archivo()
	_actualizar_valores()
	pass # Replace with function body.


func _on_retroceder_button_pressed():
	ButtonClick.button_click()
	ventanaActual -= 1
	if(ventanaActual == ventana.MATCH):
		$SiguienteButton.visible = true
	if(ventanaActual == ventana.PUZZLE):
		$RetrocederButton.visible = false
	_leer_archivo()
	_actualizar_valores()
	pass # Replace with function body.


func _on_salir_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_principal.tscn")
	pass # Replace with function body.
