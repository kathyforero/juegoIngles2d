extends Control

# ------------------------------------------------------------
# Assets
# ------------------------------------------------------------
const STAR_BRIGHT_PATH := "res://Sprites/mini_games/star - timeattack.png"
const STAR_EMPTY_PATH  := "res://Sprites/mini_games/star empty - timeattack.png"
const START_ICON_EN_PATH := "res://Sprites/buttons/play.png"
const START_ICON_ES_PATH := "res://Sprites/buttons/btn_jugar_principal.png"

@onready var STAR_BRIGHT: Texture2D = load(STAR_BRIGHT_PATH)
@onready var STAR_EMPTY: Texture2D  = load(STAR_EMPTY_PATH)

# ------------------------------------------------------------
# NODES (según tu escena nueva)
# ------------------------------------------------------------
@onready var lbl_title: Label = get_node_or_null("TextureRect/LblTittle")

@onready var btn_start: Button = $UI/Board/BtnStart
@onready var lbl_time_big: Label = $UI/Board/PanelTime/LblTimeBig

# Labels
@onready var lbl_minigames_title: Label = $UI/Board/PanelMinigames/LblMinigamesTitle
@onready var lbl_difficulty_title: Label = $UI/Board/PanelDifficulty/LblDifficultyTitle

# Minigames
@onready var btn_puzzles: Button = $UI/Board/PanelMinigames/BtnPuzzles
@onready var btn_matchit: Button = $UI/Board/PanelMinigames/BtnMatchIt
@onready var btn_orderit: Button = $UI/Board/PanelMinigames/BtnOrderIt

# Difficulty (stars)
@onready var btn_star1: Button = $UI/Board/PanelDifficulty/BtnStar1
@onready var btn_star2: Button = $UI/Board/PanelDifficulty/BtnStar2
@onready var btn_star3: Button = $UI/Board/PanelDifficulty/BtnStar3

# Time
@onready var btn_60: Button = $UI/Board/PanelTime/Btn60
@onready var btn_120: Button = $UI/Board/PanelTime/Btn120
@onready var btn_180: Button = $UI/Board/PanelTime/Btn180

# ------------------------------------------------------------
# STATE
# ------------------------------------------------------------
var en: bool = false

var selected_game_id: int = Score.Games.Puzzle
var selected_diff_key: String = "medium"
var selected_seconds: int = 120

# Feedback visual minijuego seleccionado
var _mg_default_scales: Dictionary = {}

# ------------------------------------------------------------
# Señal "update_scene" (para no romper warnings viejos)
# ------------------------------------------------------------
func _enter_tree() -> void:
	if not has_signal("update_scene"):
		add_user_signal("update_scene", [{"name":"scene_path","type": TYPE_STRING}])

	var topbar := get_node_or_null("UI/Board/TopBar")
	if topbar and not topbar.has_signal("update_scene"):
		topbar.add_user_signal("update_scene", [{"name":"scene_path","type": TYPE_STRING}])


# ------------------------------------------------------------
# Language load
# ------------------------------------------------------------
func load_language_setting() -> bool:
	if FileAccess.file_exists("res://language_setting.json"):
		var json_as_text = FileAccess.get_file_as_string("res://language_setting.json")
		var data = JSON.parse_string(json_as_text)
		if typeof(data) == TYPE_DICTIONARY and data.has("english"):
			return data["english"]
	return false


func _ready() -> void:
	en = load_language_setting()
	
	# --- Back button: decirle a TopBar a qué escena volver ---
	var topbar := get_node_or_null("UI/Board/TopBar")
	if topbar and topbar.has_signal("update_scene"):
		topbar.emit_signal("update_scene", "menu_juegos")
	
	# Validación de assets (para que no “parezca bug” si falta import)
	if STAR_BRIGHT == null:
		push_warning("STAR_BRIGHT no cargó: %s" % STAR_BRIGHT_PATH)
	if STAR_EMPTY == null:
		push_warning("STAR_EMPTY no cargó: %s" % STAR_EMPTY_PATH)

	_apply_start_icon()
	_cache_minigame_visual_defaults()

	# --- Conexiones ---
	btn_start.pressed.connect(_on_BtnStart_pressed)

	# Minijuegos: toggle + forzado + feedback visual
	btn_puzzles.toggle_mode = true
	btn_matchit.toggle_mode = true
	btn_orderit.toggle_mode = true
	btn_puzzles.toggled.connect(func(on): _select_game("puzzle", on))
	btn_matchit.toggled.connect(func(on): _select_game("match", on))
	btn_orderit.toggled.connect(func(on): _select_game("order", on))

	# ⭐ Dificultad: NO usamos toggled. Usamos "pressed" como rating.
	# (Esto arregla tus 3 casos al 100% sin estados raros.)
	btn_star1.toggle_mode = false
	btn_star2.toggle_mode = false
	btn_star3.toggle_mode = false
	btn_star1.pressed.connect(func(): _set_difficulty_level(1))
	btn_star2.pressed.connect(func(): _set_difficulty_level(2))
	btn_star3.pressed.connect(func(): _set_difficulty_level(3))

	# Tiempo: puedes dejar toggle para indicar selección (opcional)
	btn_60.toggle_mode = true
	btn_120.toggle_mode = true
	btn_180.toggle_mode = true
	btn_60.toggled.connect(func(on): _select_time(60, on))
	btn_120.toggled.connect(func(on): _select_time(120, on))
	btn_180.toggled.connect(func(on): _select_time(180, on))

	# --- Defaults solicitados: Puzzles + Medium + 120s ---
	selected_game_id = Score.Games.Puzzle
	selected_diff_key = "medium"
	selected_seconds = 120

	_force_toggle(btn_puzzles, [btn_matchit, btn_orderit])
	_set_minigame_visuals(btn_puzzles)

	_set_difficulty_level(2)  # medium => 1-2 bright, 3 empty
	_force_toggle(btn_120, [btn_60, btn_180])
	_update_time_label()

	_apply_language()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and is_visible_in_tree():
		if not is_node_ready():
			return
		var new_lang := load_language_setting()
		if new_lang != en:
			en = new_lang
			_apply_language()
			_apply_start_icon()
			_update_time_label()


# ------------------------------------------------------------
# UI helpers
# ------------------------------------------------------------
func _apply_start_icon() -> void:
	var path := START_ICON_EN_PATH if en else START_ICON_ES_PATH
	var tex: Texture2D = load(path)
	if tex:
		btn_start.icon = tex
		btn_start.expand_icon = true
		btn_start.flat = true
		btn_start.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	else:
		push_warning("BtnStart icon no cargó: %s" % path)


func _apply_language() -> void:
	if lbl_title == null:
		push_error("TimeAttackConfig: No se encontró lbl_title en ruta TextureRect/LblTittle. Revisa el nombre del nodo.")
		return
		
	# Title
	lbl_title.text = "TURBO\nMODE" if en else "MODO\nTURBO"

	# Labels
	lbl_minigames_title.text = "CHOOSE MINIGAME" if en else "ELEGIR MINIJUEGO"
	lbl_difficulty_title.text = "CHOOSE\nDIFFICULTY" if en else "ELEGIR\nDIFICULTAD"

	# Time buttons
	var suf := _time_suffix()
	btn_60.text = "60\n%s" % suf
	btn_120.text = "120\n%s" % suf
	btn_180.text = "180\n%s" % suf

	_update_time_label()


func _time_suffix() -> String:
	return "SEC" if en else "SEG"


func _update_time_label() -> void:
	lbl_time_big.text = "%d %s" % [selected_seconds, _time_suffix()]


# ------------------------------------------------------------
# Minigame selection (feedback visual)
# ------------------------------------------------------------
func _cache_minigame_visual_defaults() -> void:
	_mg_default_scales[btn_puzzles] = btn_puzzles.scale
	_mg_default_scales[btn_matchit] = btn_matchit.scale
	_mg_default_scales[btn_orderit] = btn_orderit.scale
	call_deferred("_center_pivots")


func _center_pivots() -> void:
	for b in [btn_puzzles, btn_matchit, btn_orderit]:
		b.pivot_offset = b.size * 0.5


func _set_minigame_visuals(selected_btn: Button) -> void:
	# Se nota clarito: el elegido “respira” (zoom + brillo leve)
	for b in [btn_puzzles, btn_matchit, btn_orderit]:
		var base_scale: Vector2 = _mg_default_scales.get(b, Vector2.ONE)
		if b == selected_btn:
			b.scale = base_scale * Vector2(1.07, 1.07)
			b.modulate = Color(1.15, 1.15, 1.15, 1.0)
		else:
			b.scale = base_scale
			b.modulate = Color(1, 1, 1, 1)


func _select_game(which: String, on: bool) -> void:
	if not on:
		# no permitir "ninguno seleccionado"
		match selected_game_id:
			Score.Games.Puzzle: btn_puzzles.set_pressed_no_signal(true)
			Score.Games.MatchIt: btn_matchit.set_pressed_no_signal(true)
			Score.Games.OrderIt: btn_orderit.set_pressed_no_signal(true)
		return

	match which:
		"puzzle":
			selected_game_id = Score.Games.Puzzle
			_force_toggle(btn_puzzles, [btn_matchit, btn_orderit])
			_set_minigame_visuals(btn_puzzles)
		"match":
			selected_game_id = Score.Games.MatchIt
			_force_toggle(btn_matchit, [btn_puzzles, btn_orderit])
			_set_minigame_visuals(btn_matchit)
		"order":
			selected_game_id = Score.Games.OrderIt
			_force_toggle(btn_orderit, [btn_puzzles, btn_matchit])
			_set_minigame_visuals(btn_orderit)


# ------------------------------------------------------------
# Difficulty (⭐⭐⭐) - EXACTO como pediste (3 casos)
# ------------------------------------------------------------
func _set_difficulty_level(level: int) -> void:
	level = clamp(level, 1, 3)

	match level:
		1: selected_diff_key = "easy"
		2: selected_diff_key = "medium"
		3: selected_diff_key = "hard"

	# Si por alguna razón no cargaron texturas, no hacemos nada raro
	if STAR_BRIGHT == null or STAR_EMPTY == null:
		return

	# Caso 1: 1 bright, 2-3 empty
	# Caso 2: 1-2 bright, 3 empty
	# Caso 3: 1-2-3 bright
	btn_star1.icon = STAR_BRIGHT
	btn_star2.icon = STAR_BRIGHT if level >= 2 else STAR_EMPTY
	btn_star3.icon = STAR_BRIGHT if level >= 3 else STAR_EMPTY


# ------------------------------------------------------------
# Time
# ------------------------------------------------------------
func _select_time(seconds: int, on: bool) -> void:
	if not on:
		# No permitir que quede “ninguno seleccionado”
		match selected_seconds:
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


func _force_toggle(on_btn: Button, others: Array) -> void:
	on_btn.set_pressed_no_signal(true)
	for b in others:
		b.set_pressed_no_signal(false)


# ------------------------------------------------------------
# Start
# ------------------------------------------------------------
func _on_BtnStart_pressed() -> void:
	ButtonClick.button_click()

	Score.reset_run_state()
	Score.set_mode_time_attack(selected_seconds, selected_game_id, selected_diff_key)
	Score.LatestGame = selected_game_id

	var scene_path := _scene_for(selected_game_id, selected_diff_key)
	get_tree().change_scene_to_file(scene_path)


func _scene_for(game_id: int, diff_key: String) -> String:
	match game_id:
		Score.Games.Puzzle:
			return "res://Escenas/Games/Puzzle%s.tscn" % _cap(diff_key)
		Score.Games.MatchIt:
			return "res://Escenas/Games/Match%s.tscn" % _cap(diff_key)
		Score.Games.OrderIt:
			return "res://Escenas/Games/Order%s.tscn" % _cap(diff_key)
		_:
			return "res://Escenas/Games/MatchEasy.tscn"


func _cap(d: String) -> String:
	match d:
		"easy": return "Easy"
		"medium": return "Medium"
		"hard": return "Hard"
		_: return "Easy"
