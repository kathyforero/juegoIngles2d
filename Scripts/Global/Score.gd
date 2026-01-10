extends Node

# =========================
# Scores (modo clásico)
# =========================
var PlayerScore = 0
var OrderItScore = 0
var PuzzleScore = 0
var MatchItScore = 0

enum Games { OrderIt, Puzzle, MatchIt }
var LatestGame = null

# Puntaje mostrado en PuntajeScreen
var newScore = 0
var fastBonus = 0
var perfectBonus = 0

# Info del último intento (ya lo usas en Puntaje.gd)
var latest_total_score : int = 0
var is_new_best : bool = false
var best_context : Dictionary = {}

# =========================
# Dificultad (existente)
# =========================
const difficult = {
	"easy": "easy",
	"medium": "medium",
	"hard": "hard"
}
var actualDifficult = difficult["easy"]

# =========================
# NUEVO: Modos de juego
# =========================
# CLASSIC: modo normal (con records clásicos)
# TIME_ATTACK: contrarreloj (records separados en rama time_attack)
# PRACTICE: práctica libre (sin records, sin tiempo, loop de rondas)
enum Mode { CLASSIC, TIME_ATTACK, PRACTICE }
var current_mode : int = Mode.CLASSIC

const TIME_ATTACK_RANDOM_GAME := -1
var time_attack_seconds : int = 60
var time_attack_game : int = TIME_ATTACK_RANDOM_GAME # Games.* o -1 para Random

# Para Time Attack (se juega hasta que el tiempo se acaba)
var levels_completed : int = 0

# Multiplicadores para que 60s valga más (más difícil)
const TIME_ATTACK_TIME_MULT := {
	60: 1.50,
	120: 1.25,
	180: 1.00
}

func _ready():
	PlayerScore = OrderItScore + PuzzleScore + MatchItScore
	_load_achievements()

func reset_run_state() -> void:
	newScore = 0
	fastBonus = 0
	perfectBonus = 0
	latest_total_score = 0
	is_new_best = false
	levels_completed = 0

func is_classic() -> bool:
	return current_mode == Mode.CLASSIC

func is_time_attack() -> bool:
	return current_mode == Mode.TIME_ATTACK

func is_practice() -> bool:
	return current_mode == Mode.PRACTICE

func set_mode_classic() -> void:
	current_mode = Mode.CLASSIC
	time_attack_game = TIME_ATTACK_RANDOM_GAME
	time_attack_seconds = 60
	levels_completed = 0

func set_mode_time_attack(seconds:int, game:int, diff:String) -> void:
	current_mode = Mode.TIME_ATTACK
	time_attack_seconds = seconds
	time_attack_game = game
	actualDifficult = diff
	levels_completed = 0
	# En este modo NO usamos velocidad
	fastBonus = 0

func set_mode_practice(diff:String) -> void:
	# Importante: práctica debe mantenerse ON hasta que el usuario la apague.
	# Por eso este setter NO depende de escenas, solo del menú.
	current_mode = Mode.PRACTICE
	actualDifficult = diff
	# Dejamos estos en defaults neutrales (no se usan en práctica)
	time_attack_game = TIME_ATTACK_RANDOM_GAME
	time_attack_seconds = 60
	reset_run_state()

func calc_time_attack_score(levels:int, seconds:int, precision_bonus:int) -> int:
	var mult := float(TIME_ATTACK_TIME_MULT.get(seconds, 1.0))
	var base := int(levels * 20 * mult)
	if levels <= 0:
		precision_bonus = 0
	return base + precision_bonus

func can_persist_records() -> bool:
	# En Practice NO se guarda nada.
	return current_mode != Mode.PRACTICE

func uses_timer() -> bool:
	# Practice no usa timer ni HUD countdown
	return current_mode != Mode.PRACTICE

func practice_label(is_english: bool) -> String:
	return "PRACTICE" if is_english else "PRÁCTICA"

# =========================
# Achievements / Medals (port desde ladoB)
# =========================

const ACHIEVEMENTS_FILE := "/Progress/achievements.dat"

const ACHIEVEMENT_TEXTURES := {
	"puzzle":  "res://Sprites/buttons/LogroPuzzle.png",
	"match":   "res://Sprites/buttons/LogroMatchIt.png",
	"order":   "res://Sprites/buttons/LogroOrderIt.png",
	"speed":   "res://Sprites/buttons/LogroSpeed.png",
	"perfect": "res://Sprites/buttons/LogroPerfect.png"
}

const ACHIEVEMENT_UNKNOWN_TEXTURE := "res://Sprites/buttons/LogroUnknown.png"

var achievements_data : Dictionary = {}
var pending_achievements : Array = []

func _get_achievements_path() -> String:
	return Global.rutaArchivos + ACHIEVEMENTS_FILE

func _ensure_progress_dir() -> void:
	var dir_path = Global.rutaArchivos + "/Progress"
	if DirAccess.dir_exists_absolute(dir_path):
		return
	DirAccess.make_dir_recursive_absolute(dir_path)

func _default_achievements() -> Dictionary:
	return {
		"achievements": {
			"puzzle": false,
			"match": false,
			"order": false,
			"speed": false,
			"perfect": false
		},
		"completed": {
			"puzzle": {"easy": false, "medium": false, "hard": false},
			"match":  {"easy": false, "medium": false, "hard": false},
			"order":  {"easy": false, "medium": false, "hard": false}
		}
	}

func _load_achievements() -> void:
	_ensure_progress_dir()

	var defaults := _default_achievements()
	var path := _get_achievements_path()

	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		var data = file.get_var()
		file.close()

		# Merge “seguro” (por si agregas logros nuevos luego)
		achievements_data = defaults
		if typeof(data) == TYPE_DICTIONARY:
			var saved_ach = data.get("achievements", {})
			for key in achievements_data["achievements"].keys():
				if saved_ach.has(key):
					achievements_data["achievements"][key] = saved_ach[key]

			var saved_completed = data.get("completed", {})
			for game_key in achievements_data["completed"].keys():
				if saved_completed.has(game_key):
					for diff_key in achievements_data["completed"][game_key].keys():
						if saved_completed[game_key].has(diff_key):
							achievements_data["completed"][game_key][diff_key] = saved_completed[game_key][diff_key]
	else:
		achievements_data = defaults
		_save_achievements()

func _save_achievements() -> void:
	var path := _get_achievements_path()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_var(achievements_data)
	file.close()

func _unlock_achievement(achievement_id: String) -> void:
	if !achievements_data["achievements"].get(achievement_id, false):
		achievements_data["achievements"][achievement_id] = true
		if !pending_achievements.has(achievement_id):
			pending_achievements.append(achievement_id)

func _mark_completed(game_id: String, difficulty_id: String) -> void:
	if !achievements_data["completed"].has(game_id):
		return
	if achievements_data["completed"][game_id].has(difficulty_id):
		achievements_data["completed"][game_id][difficulty_id] = true

func _check_game_achievement(game_id: String) -> void:
	if !achievements_data["completed"].has(game_id):
		return
	var c = achievements_data["completed"][game_id]
	if c["easy"] and c["medium"] and c["hard"]:
		_unlock_achievement(game_id)

# API principal:
# - Classic: cuenta completado + puede dar speed/perfect
# - Time Attack: cuenta completado (si llamas con from_time_attack=true) pero NO da speed/perfect
# - Practice: NO hace nada
func register_minigame_victory(game_id: String, difficulty_id: String, time_spent: float, is_perfect: bool, from_time_attack: bool=false) -> void:
	if current_mode == Mode.PRACTICE:
		return

	_mark_completed(game_id, difficulty_id)
	_check_game_achievement(game_id)

	# Speed/Perfect solo en Classic (ladoB se basaba en ronda con cronómetro)
	if !from_time_attack:
		if time_spent >= 0.0 and time_spent <= 30.0:
			_unlock_achievement("speed")
		if is_perfect:
			_unlock_achievement("perfect")

	_save_achievements()

func has_pending_achievement() -> bool:
	return pending_achievements.size() > 0

func pop_next_pending_achievement() -> String:
	if pending_achievements.size() == 0:
		return ""
	return str(pending_achievements.pop_front())

func get_achievement_texture_path(achievement_id: String) -> String:
	return ACHIEVEMENT_TEXTURES.get(achievement_id, "")

func get_unknown_achievement_texture_path() -> String:
	return ACHIEVEMENT_UNKNOWN_TEXTURE

func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievements_data.get("achievements", {}).get(achievement_id, false)

func get_unlocked_achievements_count() -> int:
	var count := 0
	for key in achievements_data["achievements"].keys():
		if achievements_data["achievements"][key]:
			count += 1
	return count

func get_achievement_message(achievement_id: String, english: bool) -> String:
	var name := "Achievement"
	match achievement_id:
		"puzzle":  name = "Puzzle"
		"match":   name = "Match It"
		"order":   name = "Order It"
		"speed":   name = "Speed"
		"perfect": name = "Perfect"

	if english:
		match achievement_id:
			"puzzle", "match", "order":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round on every difficulty of this minigame. Keep it up :)"
			"speed":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round in 30 seconds or less. Keep it up :)"
			"perfect":
				return "Congratulations! You earned the \"" + name + "\" achievement for completing a round without mistakes. Keep it up :)"
			_:
				return "Congratulations! You earned a new achievement. Keep it up :)"
	else:
		match achievement_id:
			"puzzle", "match", "order":
				return "¡Felicidades! Has obtenido el logro \"" + name + "\" por completar una ronda en cada dificultad de este minijuego. ¡Sigue así! :)"
			"speed":
				return "¡Felicidades! Has obtenido el logro \"" + name + "\" por completar una ronda en 30 segundos o menos. ¡Sigue así! :)"
			"perfect":
				return "¡Felicidades! Has obtenido el logro \"" + name + "\" por completar una ronda sin equivocarte. ¡Sigue así! :)"
			_:
				return "¡Felicidades! Has obtenido un nuevo logro. ¡Sigue así! :)"
