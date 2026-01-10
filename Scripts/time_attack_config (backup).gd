extends Control

# ====== NODES (tu escena actual) ======
@onready var lbl_title: Label = $UI/Board/TopBar/LblTitle
@onready var btn_start: Button = $UI/Board/BtnStart
@onready var lbl_time_big: Label = $UI/Board/PanelTime/LblTimeBig

# Minigames
@onready var btn_puzzles: Button = $UI/Board/PanelMinigames/BtnPuzzles
@onready var btn_matchit: Button = $UI/Board/PanelMinigames/BtnMatchIt
@onready var btn_orderit: Button = $UI/Board/PanelMinigames/BtnOrderIt

# Difficulty
@onready var btn_star1: Button = $UI/Board/PanelDifficulty/BtnStar1
@onready var btn_star2: Button = $UI/Board/PanelDifficulty/BtnStar2
@onready var btn_star3: Button = $UI/Board/PanelDifficulty/BtnStar3

# Time
@onready var btn_60: Button = $UI/Board/PanelTime/Btn60
@onready var btn_120: Button = $UI/Board/PanelTime/Btn120
@onready var btn_180: Button = $UI/Board/PanelTime/Btn180

# ====== STATE ======
var en: bool = false
var selected_game_id: int = Score.Games.MatchIt
var selected_diff_key: String = "medium"
var selected_seconds: int = 120


# -------------------------------------------------------------------
# FIX WARNING btn_go_back: crea la señal update_scene ANTES del _ready()
# (tu back ya trae sus funciones, aquí solo evitamos el warning)
# -------------------------------------------------------------------
func _enter_tree() -> void:
	# por si el back busca la señal en el root
	if not has_signal("update_scene"):
		add_user_signal("update_scene", [{"name":"scene_path","type": TYPE_STRING}])

	# por si el back busca la señal en su padre (TopBar es Control)
	var topbar := get_node_or_null("UI/Board/TopBar")
	if topbar and not topbar.has_signal("update_scene"):
		topbar.add_user_signal("update_scene", [{"name":"scene_path","type": TYPE_STRING}])


func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false


func _ready() -> void:
	en = load_language_setting()

	# Importante: habilita toggle_mode donde tu escena no lo tenía
	_ensure_toggle_mode()
	
	var topbar := $UI/Board/TopBar

	# crea la señal en TopBar (el padre del botón back), si no existe
	if not topbar.has_signal("update_scene"):
		topbar.add_user_signal("update_scene", [{"name":"scene","type": TYPE_STRING}])

	# envía el nombre de la escena a la que debe volver (SIN .tscn)
	topbar.emit_signal("update_scene", "menu_juegos")

	# Conecta SOLO lo que manejamos aquí.
	# Back y Sound: NO tocamos (ya existen y tienen su lógica).
	btn_start.pressed.connect(_on_BtnStart_pressed)

	btn_puzzles.toggled.connect(func(on): _select_game("puzzle", on))
	btn_matchit.toggled.connect(func(on): _select_game("match", on))
	btn_orderit.toggled.connect(func(on): _select_game("order", on))

	btn_star1.toggled.connect(func(on): _select_diff(1, on))
	btn_star2.toggled.connect(func(on): _select_diff(2, on))
	btn_star3.toggled.connect(func(on): _select_diff(3, on))

	btn_60.toggled.connect(func(on): _select_time(60, on))
	btn_120.toggled.connect(func(on): _select_time(120, on))
	btn_180.toggled.connect(func(on): _select_time(180, on))

	_apply_language()

	# Defaults: MatchIt + Medium + 120
	_force_toggle(btn_matchit, [btn_puzzles, btn_orderit])
	_force_toggle(btn_star2, [btn_star1, btn_star3])
	_force_toggle(btn_120, [btn_60, btn_180])

	selected_game_id = Score.Games.MatchIt
	selected_diff_key = "medium"
	selected_seconds = 120
	_update_time_label()


func _ensure_toggle_mode() -> void:
	# Minigames ya tienen toggle_mode en tu escena, pero no hace daño.
	btn_puzzles.toggle_mode = true
	btn_matchit.toggle_mode = true
	btn_orderit.toggle_mode = true

	# Aquí estaba el bug en tu .tscn:
	btn_star1.toggle_mode = true
	btn_star2.toggle_mode = true
	btn_star3.toggle_mode = true

	btn_60.toggle_mode = true
	btn_120.toggle_mode = true
	btn_180.toggle_mode = true


# ====== UI text ======
func _apply_language() -> void:
	lbl_title.text = "TIME ATTACK" if en else "CONTRARRELOJ"

	$UI/Board/PanelMinigames/LblMinigamesTitle.text = "CHOOSE MINIGAME" if en else "ELEGIR JUEGO"
	$UI/Board/PanelDifficulty/LblDifficultyTitle.text = "CHOOSE DIFFICULTY" if en else "ELEGIR DIFICULTAD"

	# Estrellas (así se ven como en tu referencia)
	btn_star1.text = "★☆☆"
	btn_star2.text = "★★☆"
	btn_star3.text = "★★★"

	btn_start.text = "START" if en else "INICIAR"
	_update_time_label()


func _update_time_label() -> void:
	lbl_time_big.text = ("%d SEC" % selected_seconds) if en else ("%d SEG" % selected_seconds)


# ====== Toggle helpers ======
func _force_toggle(keep_on: Button, others: Array) -> void:
	keep_on.set_pressed_no_signal(true)
	for b in others:
		if b and b is Button:
			(b as Button).set_pressed_no_signal(false)


# ====== Selections ======
func _select_game(which: String, on: bool) -> void:
	if not on:
		# modo radio: no permitimos “ninguno”
		match which:
			"puzzle": btn_puzzles.set_pressed_no_signal(true)
			"match": btn_matchit.set_pressed_no_signal(true)
			"order": btn_orderit.set_pressed_no_signal(true)
		return

	match which:
		"puzzle":
			selected_game_id = Score.Games.Puzzle
			_force_toggle(btn_puzzles, [btn_matchit, btn_orderit])
		"match":
			selected_game_id = Score.Games.MatchIt
			_force_toggle(btn_matchit, [btn_puzzles, btn_orderit])
		"order":
			selected_game_id = Score.Games.OrderIt
			_force_toggle(btn_orderit, [btn_puzzles, btn_matchit])


func _select_diff(stars: int, on: bool) -> void:
	if not on:
		match stars:
			1: btn_star1.set_pressed_no_signal(true)
			2: btn_star2.set_pressed_no_signal(true)
			3: btn_star3.set_pressed_no_signal(true)
		return

	match stars:
		1:
			selected_diff_key = "easy"
			_force_toggle(btn_star1, [btn_star2, btn_star3])
		2:
			selected_diff_key = "medium"
			_force_toggle(btn_star2, [btn_star1, btn_star3])
		3:
			selected_diff_key = "hard"
			_force_toggle(btn_star3, [btn_star1, btn_star2])


func _select_time(seconds: int, on: bool) -> void:
	if not on:
		match seconds:
			60: btn_60.set_pressed_no_signal(true)
			120: btn_120.set_pressed_no_signal(true)
			180: btn_180.set_pressed_no_signal(true)
		return

	selected_seconds = seconds
	match seconds:
		60: _force_toggle(btn_60, [btn_120, btn_180])
		120: _force_toggle(btn_120, [btn_60, btn_180])
		180: _force_toggle(btn_180, [btn_60, btn_120])

	_update_time_label()


# ====== Start ======
func _on_BtnStart_pressed() -> void:
	ButtonClick.button_click()

	Score.reset_run_state()
	Score.set_mode_time_attack(selected_seconds, selected_game_id, selected_diff_key)
	Score.LatestGame = selected_game_id

	var scene_path := _scene_for(selected_game_id, selected_diff_key)
	get_tree().change_scene_to_file(scene_path)


func _scene_for(game_id:int, diff_key:String) -> String:
	match game_id:
		Score.Games.Puzzle:
			return "res://Escenas/Games/Puzzle%s.tscn" % _cap(diff_key)
		Score.Games.MatchIt:
			return "res://Escenas/Games/Match%s.tscn" % _cap(diff_key)
		Score.Games.OrderIt:
			return "res://Escenas/Games/Order%s.tscn" % _cap(diff_key)
		_:
			return "res://Escenas/Games/MatchEasy.tscn"


func _cap(d:String) -> String:
	match d:
		"easy": return "Easy"
		"medium": return "Medium"
		"hard": return "Hard"
		_: return "Easy"
