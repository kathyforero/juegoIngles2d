extends Node2D

# =========================
# Estado / Config
# =========================
var velocidad = 0
var precision = 0
var niveles = 0

var maximoVelocidad = 300
var maximoPrecision = 300
var maximoNiveles = 300
var maximoScaleX = 0.256

enum ventana { PUZZLE = 0, MATCH = 1, ORDER = 2 }
var ventanaActual = ventana.PUZZLE
var posActual = 0

var ejecutablePath = Global.rutaArchivos
var en: bool = false  # idioma (true = EN, false = ES)

# =========================
# Nodos (nuevo layout)
# =========================
@onready var lbl_title: Label = $Tablero/Tittle
@onready var lbl_header1: Label = $Tablero/Header1
@onready var lbl_header2: Label = $Tablero/Header2
@onready var lbl_header3: Label = $Tablero/Header3

@onready var lbl_diff1: Label = $Tablero/Difficulty1
@onready var lbl_diff2: Label = $Tablero/Difficulty2
@onready var lbl_diff3: Label = $Tablero/Difficulty3

@onready var lbl_easy_name: Label = $Tablero/EasyNameLabel
@onready var lbl_med_name: Label = $Tablero/MediumNameLabel
@onready var lbl_hard_name: Label = $Tablero/HardNameLabel

@onready var lbl_easy_score: Label = $Tablero/EasyScoreLabel
@onready var lbl_med_score: Label = $Tablero/MediumScoreLabel
@onready var lbl_hard_score: Label = $Tablero/HardScoreLabel

@onready var lbl_minijuego: Label = $MinijuegoNombre
@onready var lbl_seccion: Label = $LblSeccion

@onready var btn_next = $SiguienteButton
@onready var btn_back = $RetrocederButton

# =========================
# i18n
# =========================
func load_language_setting() -> bool:
	# Misma lógica que el resto del proyecto
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return bool(data["english"])
	return false

func _apply_language_texts() -> void:
	# Título principal
	lbl_title.text = "BEST SCORES" if en else "MEJORES PUNTAJES"

	# Encabezados de columnas
	lbl_header1.text = "Difficulty" if en else "Dificultad"
	lbl_header2.text = "Player" if en else "Jugador"
	lbl_header3.text = "Score" if en else "Puntaje"

	# Dificultades (solo texto visual)
	lbl_diff1.text = "Easy" if en else "Fácil"
	lbl_diff2.text = "Medium" if en else "Medio"
	# Tú tenías "Difficult" en el .tscn; lo normal aquí es "Hard"
	lbl_diff3.text = "Hard" if en else "Difícil"

	# Sección
	lbl_seccion.text = "Scores" if en else "Puntajes"

	# Nombre del minijuego (esto depende de ventanaActual)
	_update_minigame_label()

func _update_minigame_label() -> void:
	match ventanaActual:
		ventana.PUZZLE:
			# "Puzzle" funciona igual en ambos
			lbl_minijuego.text = "Puzzle"
		ventana.MATCH:
			# Mantengo el nombre oficial del minijuego
			lbl_minijuego.text = "Match It"
		ventana.ORDER:
			lbl_minijuego.text = "Order It"

# =========================
# Ready / Loop
# =========================
func _ready():
	btn_back.visible = false

	# Cargar idioma y aplicarlo
	en = load_language_setting()
	_apply_language_texts()

	# Cargar puntajes y render
	_leer_archivo()
	_actualizar_valores()

func _process(delta):
	pass

# =========================
# Puntajes (best-of-both)
# =========================
func _leer_archivo():
	match ventanaActual:
		ventana.PUZZLE:
			_cargar_puntajes(ejecutablePath + "/Scores/puntajesPuzzle.dat")
		ventana.MATCH:
			_cargar_puntajes(ejecutablePath + "/Scores/puntajesMatch.dat")
		ventana.ORDER:
			_cargar_puntajes(ejecutablePath + "/Scores/puntajesOrder.dat")

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

func _get_best_of_both(raw: Dictionary, diff: String) -> Dictionary:
	# NORMAL está al nivel raíz
	var normal_scores: Dictionary = raw
	# TIME ATTACK está en rama aparte (si no existe, queda vacío)
	var ta_scores: Dictionary = raw.get("time_attack", {})

	var n_dict: Dictionary = normal_scores.get(diff, {})
	var t_dict: Dictionary = ta_scores.get(diff, {})

	var n_score: int = _get_total_from_dict(normal_scores, diff)
	var t_score: int = _get_total_from_dict(ta_scores, diff)

	var n_name: String = str(n_dict.get("name", "---"))
	var t_name: String = str(t_dict.get("name", "---"))

	# Si empatan, preferimos NORMAL para que no “salte” raro
	if t_score > n_score:
		return {"score": t_score, "name": t_name}

	return {"score": n_score, "name": n_name}

func _cargar_puntajes(path: String) -> void:
	if not FileAccess.file_exists(path):
		lbl_easy_score.text = "0"
		lbl_easy_name.text = "---"
		lbl_med_score.text = "0"
		lbl_med_name.text = "---"
		lbl_hard_score.text = "0"
		lbl_hard_name.text = "---"
		return

	var file := FileAccess.open(path, FileAccess.READ)
	var raw = file.get_var()
	file.close()

	# ✅ Best-of-both: comparar NORMAL vs TIME ATTACK por dificultad
	var easy_best := _get_best_of_both(raw, "easy")
	var med_best := _get_best_of_both(raw, "medium")
	var hard_best := _get_best_of_both(raw, "hard")

	lbl_easy_score.text = str(int(easy_best["score"]))
	lbl_med_score.text = str(int(med_best["score"]))
	lbl_hard_score.text = str(int(hard_best["score"]))

	lbl_easy_name.text = str(easy_best["name"])
	lbl_med_name.text = str(med_best["name"])
	lbl_hard_name.text = str(hard_best["name"])

func _actualizar_valores():
	# Solo actualiza lo que cambia con la ventana actual (nombre del minijuego)
	_update_minigame_label()

# =========================
# Botones
# =========================
func _on_siguiente_button_pressed():
	ButtonClick.button_click()
	ventanaActual += 1

	if ventanaActual == ventana.ORDER:
		btn_next.visible = false
	if ventanaActual > 0:
		btn_back.visible = true

	_leer_archivo()
	_actualizar_valores()

func _on_retroceder_button_pressed():
	ButtonClick.button_click()
	ventanaActual -= 1

	if ventanaActual == ventana.MATCH:
		btn_next.visible = true
	if ventanaActual == ventana.PUZZLE:
		btn_back.visible = false

	_leer_archivo()
	_actualizar_valores()

func _on_salir_button_pressed():
	ButtonClick.button_click()
	get_tree().change_scene_to_file("res://Escenas/menu_principal.tscn")
